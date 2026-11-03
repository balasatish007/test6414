package com.bcbsa.custom.imap.notification.scheduler;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.liferay.dispatch.executor.BaseDispatchTaskExecutor;
import com.liferay.dispatch.executor.DispatchTaskExecutor;
import com.liferay.dispatch.executor.DispatchTaskExecutorOutput;
import com.liferay.dispatch.executor.DispatchTaskStatus;
import com.liferay.dispatch.model.DispatchLog;
import com.liferay.dispatch.model.DispatchTrigger;
import com.liferay.dispatch.service.DispatchLogLocalService;
import com.liferay.dispatch.service.DispatchTriggerLocalService;
import com.liferay.portal.kernel.cluster.ClusterMasterExecutorUtil;
import com.liferay.portal.kernel.dao.orm.DynamicQuery;
import com.liferay.portal.kernel.dao.orm.RestrictionsFactoryUtil;
import com.liferay.portal.kernel.log.Log;
import com.liferay.portal.kernel.log.LogFactoryUtil;
import com.liferay.portal.kernel.pop.MessageListener;
import com.liferay.portal.kernel.pop.MessageListenerException;
import com.liferay.portal.kernel.util.GetterUtil;
import com.liferay.portal.kernel.util.PropsUtil;

import java.io.IOException;
import java.io.InputStream;
import java.lang.management.ManagementFactory;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.apache.commons.io.IOUtils;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.annotations.ReferencePolicyOption;

@Component(
    immediate = true,
    service = DispatchTaskExecutor.class,
    property = {
        "dispatch.task.executor.name=Custom Discussion IMAP Notifications",
        "dispatch.task.executor.type=Custom Discussion IMAP Notifications"
    }
)
public class CustomIMAPNotificationsScheduler extends BaseDispatchTaskExecutor {

    private static final Log _log = LogFactoryUtil.getLog(CustomIMAPNotificationsScheduler.class);

    // FIX: executor type used to find this job's Dispatch trigger(s) for startup cleanup
    private static final String EXECUTOR_TYPE = "Custom Discussion IMAP Notifications";

    // FIX: timeout defaults (override in portal-ext.properties if needed)
    private static final int DEFAULT_CONNECT_TIMEOUT_MS = 15000;
    private static final int DEFAULT_READ_TIMEOUT_MS = 60000;

    /**
     * FIX: Startup auto-clear.
     * When the server restarts in the middle of a run, Dispatch leaves that run's log row
     * IN_PROGRESS forever and blocks every later run with
     * "Only one instance in progress is allowed".
     * Any IN_PROGRESS row that started before this JVM started cannot be a live run,
     * so it is marked CANCELED here.
     */
    @Activate
    protected void activate() {
        try {
            Date jvmStart = new Date(ManagementFactory.getRuntimeMXBean().getStartTime());

            for (DispatchTrigger trigger : _dispatchTriggerLocalService.getDispatchTriggers(-1, -1)) {
                if (!EXECUTOR_TYPE.equals(trigger.getDispatchTaskExecutorType())) {
                    continue;
                }

                DynamicQuery dq = _dispatchLogLocalService.dynamicQuery();
                dq.add(RestrictionsFactoryUtil.eq("dispatchTriggerId", trigger.getDispatchTriggerId()));
                dq.add(RestrictionsFactoryUtil.eq("status", DispatchTaskStatus.IN_PROGRESS.getStatus()));
                dq.add(RestrictionsFactoryUtil.lt("startDate", jvmStart));

                List<DispatchLog> orphans = _dispatchLogLocalService.dynamicQuery(dq);

                for (DispatchLog dispatchLog : orphans) {
                    dispatchLog.setStatus(DispatchTaskStatus.CANCELED.getStatus());
                    dispatchLog.setEndDate(new Date());
                    dispatchLog.setError("Auto-cleared on startup: run was in progress before server restart");
                    _dispatchLogLocalService.updateDispatchLog(dispatchLog);

                    _log.warn("Cleared stuck Graph run logId=" + dispatchLog.getDispatchLogId() +
                            " trigger='" + trigger.getName() + "' started " + dispatchLog.getStartDate());
                }
            }
        } catch (Exception e) {
            _log.error("Startup cleanup of stuck Graph runs failed", e);
        }
    }

    @Override
    public void doExecute(
            com.liferay.dispatch.model.DispatchTrigger dispatchTrigger,
            DispatchTaskExecutorOutput dispatchTaskExecutorOutput) throws Exception {

        // Cluster master check to execute only on master node
        if (!ClusterMasterExecutorUtil.isMaster()) {
            if (_log.isDebugEnabled()) {
                _log.debug("Skipping execution - not running on cluster master node");
            }
            return;
        }

        // FIX: INFO-level start/finish logging so every run is visible in PROD logs
        long startMillis = System.currentTimeMillis();
        int messageCount = 0;
        _log.info(">>> Graph Scheduler started");

        try {
            String tenantId = PropsUtil.get("graph.tenant.id");
            String clientId = PropsUtil.get("graph.client.id");
            String clientSecret = PropsUtil.get("graph.client.secret");
            String mailbox = PropsUtil.get("graph.mailbox");

            if (_log.isDebugEnabled()) {
                _log.debug("Graph access token method begin");
            }

            String accessToken = getAuthToken(tenantId, clientId, clientSecret);

            if (_log.isDebugEnabled()) {
                _log.debug("Graph access token obtained successfully");
            }

            Message[] messages = getMessagesFromGraph(accessToken, mailbox);

            if (messages == null || messages.length == 0) {
                if (_log.isDebugEnabled()) {
                    _log.debug("No messages in INBOX");
                }
                return;
            }

            messageCount = messages.length;

            notifyMessageListeners(messages);

            deleteMessages(accessToken, mailbox, messages);

        } catch (Exception ex) {
            _log.error(">>>Graph Processing Error", ex);
        } finally {
            // FIX: always logged, including the "no messages" early return and errors
            _log.info(">>> Graph Scheduler finished in " + (System.currentTimeMillis() - startMillis) +
                    " ms, messages=" + messageCount);
        }
    }

    private String getAuthToken(String tenantId, String clientId, String clientSecret) throws Exception {
        String tokenUrl = "https://login.microsoftonline.com/" + tenantId + "/oauth2/v2.0/token";

        HttpPost post = new HttpPost(tokenUrl);

        String body = "client_id=" + URLEncoder.encode(clientId, "UTF-8") +
                "&scope=" + URLEncoder.encode("https://graph.microsoft.com/.default", "UTF-8") +
                "&client_secret=" + URLEncoder.encode(clientSecret, "UTF-8") +
                "&grant_type=client_credentials";

        post.setEntity(new StringEntity(body, StandardCharsets.UTF_8));
        post.setHeader("Content-Type", "application/x-www-form-urlencoded");

        // FIX: client with timeouts (was HttpClients.createDefault() = no timeout);
        // try-with-resources closes client/response even if a timeout exception is thrown
        try (CloseableHttpClient client = _httpClient();
             CloseableHttpResponse response = client.execute(post)) {

            String responseStr = IOUtils.toString(response.getEntity().getContent(), StandardCharsets.UTF_8);

            ObjectMapper mapper = new ObjectMapper();
            JsonNode tokenJson = mapper.readTree(responseStr);

            JsonNode tokenNode = tokenJson.get("access_token");
            if (tokenNode == null) {
                throw new IllegalStateException("Graph token request failed: " + responseStr);
            }

            return tokenNode.asText();
        }
    }

    private Message[] getMessagesFromGraph(String accessToken, String mailbox) throws Exception {

        String mailboxEncoded = URLEncoder.encode(mailbox, StandardCharsets.UTF_8.name());

        /**
         * Microsoft Graph API returns messages in JSON format with the following structure:
         * {
         *   "value": [
         *     {
         *       "id": "AAMk...",
         *       "subject": "Re: Discussion Thread",
         *       "from": { "emailAddress": { "name": "...", "address": "..." } },
         *       "toRecipients": [ { "emailAddress": { ... } } ],
         *       "body": { "contentType": "html", "content": "..." },
         *       "internetMessageHeaders": [ { "name": "In-Reply-To", "value": "..." }, ... ]
         *     }
         *   ]
         * }
         *
         * We parse this JSON and convert it to javax.mail.Message objects because:
         * 1. Liferay's existing MessageListener infrastructure expects javax.mail.Message objects
         * 2. Downstream hooks and listeners rely on standard email headers (In-Reply-To, References, Thread-Index)
         * 3. The internetMessageHeaders array contains critical threading information that identifies
         *    which discussion board thread the email reply belongs to (via mb_message.* format)
         * 4. This allows us to replace deprecated IMAP with Graph API without changing any downstream code
         */

        String unreadUrl = "https://graph.microsoft.com/v1.0/users/" + mailboxEncoded +
                "/mailFolders/Inbox/messages" +
                "?$filter=isRead%20eq%20false" +
                "&$select=id,subject,from,toRecipients,ccRecipients,body,receivedDateTime," +
                "internetMessageId,conversationId,importance,hasAttachments,internetMessageHeaders";

        // FIX: _open() applies connect/read timeouts
        HttpURLConnection conn = _open(unreadUrl);
        String json;
        int status;

        try {
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Authorization", "Bearer " + accessToken);
            conn.setRequestProperty("Accept", "application/json");

            status = conn.getResponseCode();
            if (_log.isDebugEnabled()) {
                _log.debug("Graph read HTTP status: " + status);
            }

            InputStream is = (status >= 200 && status < 300) ? conn.getInputStream() : conn.getErrorStream();
            json = (is == null) ? "" : IOUtils.toString(is, StandardCharsets.UTF_8);
        } finally {
            // FIX: release the connection even if the read times out
            conn.disconnect();
        }

        if (!(status >= 200 && status < 300)) {
            _log.error("Graph read failed. HTTP " + status + " Response=" + json);
            return null;
        }

        // Parse JSON response from Graph API

        ObjectMapper mapper = new ObjectMapper();
        JsonNode value = mapper.readTree(json).path("value");

        // Convert each Graph API message to javax.mail.Message format

        List<Message> messageList = new ArrayList<>();
        Properties props = new Properties();
        Session session = Session.getInstance(props);

        for (JsonNode graphMsg : value) {
            try {
                MimeMessage message = new MimeMessage(session);

                message.setSubject(graphMsg.path("subject").asText());

                String fromEmail = graphMsg.path("from").path("emailAddress").path("address").asText();
                String fromName = graphMsg.path("from").path("emailAddress").path("name").asText();
                message.setFrom(new InternetAddress(fromEmail, fromName));

                JsonNode toRecipients = graphMsg.path("toRecipients");
                for (JsonNode recipient : toRecipients) {
                    String email = recipient.path("emailAddress").path("address").asText();
                    String name = recipient.path("emailAddress").path("name").asText();
                    message.addRecipient(Message.RecipientType.TO, new InternetAddress(email, name));
                }

                String bodyContent = graphMsg.path("body").path("content").asText();
                String bodyType = graphMsg.path("body").path("contentType").asText();
                if ("html".equalsIgnoreCase(bodyType)) {
                    message.setContent(bodyContent, "text/html; charset=utf-8");
                } else {
                    message.setText(bodyContent, "utf-8");
                }

                String receivedDateTime = graphMsg.path("receivedDateTime").asText();
                if (receivedDateTime != null && !receivedDateTime.isEmpty()) {
                    try {
                        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
                        sdf.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
                        message.setSentDate(sdf.parse(receivedDateTime));
                    } catch (Exception e) {
                        if (_log.isDebugEnabled()) {
                            _log.debug("Error parsing date", e);
                        }
                    }
                }

                String messageId = graphMsg.path("id").asText();
                message.setHeader("X-Graph-Message-Id", messageId);

                JsonNode headers = graphMsg.path("internetMessageHeaders");

                if (headers != null && headers.isArray()) {
                    for (JsonNode header : headers) {
                        String headerName = header.path("name").asText();
                        String headerValue = header.path("value").asText();

                        if (headerName != null && !headerName.isEmpty() &&
                            headerValue != null && !headerValue.isEmpty()) {

                            message.setHeader(headerName, headerValue);

                            if (_log.isDebugEnabled()) {
                                if ("In-Reply-To".equalsIgnoreCase(headerName) ||
                                    "References".equalsIgnoreCase(headerName) ||
                                    "Thread-Index".equalsIgnoreCase(headerName)) {
                                    _log.debug("CRITICAL HEADER - " + headerName + ": " + headerValue);
                                }
                            }
                        }
                    }
                } else {
                    if (_log.isDebugEnabled()) {
                        _log.debug("No internetMessageHeaders found for message: " + messageId);
                    }
                }

                message.saveChanges();
                messageList.add(message);

                if (_log.isDebugEnabled()) {
                    _log.debug("Converted message: " + message.getSubject());
                }

            } catch (Exception e) {
                _log.error("Error converting Graph message", e);
            }
        }

        return messageList.toArray(new Message[0]);
    }

    private void deleteMessages(String accessToken, String mailbox, Message[] messages) {
        String mailboxEncoded;
        try {
            mailboxEncoded = URLEncoder.encode(mailbox, StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            _log.error("Error encoding mailbox", e);
            return;
        }

        for (Message message : messages) {
            try {
                String[] graphMsgIds = message.getHeader("X-Graph-Message-Id");
                if (graphMsgIds == null || graphMsgIds.length == 0) {
                    continue;
                }
                String messageId = graphMsgIds[0];

                String url = "https://graph.microsoft.com/v1.0/users/" + mailboxEncoded + "/messages/" + messageId;

                HttpDelete delete = new HttpDelete(url);
                delete.setHeader("Authorization", "Bearer " + accessToken);

                // FIX: client with timeouts (was HttpClients.createDefault() = no timeout);
                // try-with-resources closes client/response even if a timeout exception is thrown
                try (CloseableHttpClient client = _httpClient();
                     CloseableHttpResponse response = client.execute(delete)) {

                    int statusCode = response.getStatusLine().getStatusCode();

                    if (statusCode == 204 || statusCode == 200) {
                        if (_log.isDebugEnabled()) {
                            _log.debug("Successfully deleted message - HTTP " + statusCode);
                        }
                    } else {
                        // FIX: a failed delete leaves the email in the mailbox, so log it at WARN
                        _log.warn("Graph delete returned HTTP " + statusCode + " for messageId=" + messageId);
                    }
                }

            } catch (Exception e) {
                _log.error("Error deleting message", e);
            }
        }
    }

    protected void notifyMessageListeners(javax.mail.Message[] messages) throws MessageListenerException, MessagingException {

        if (_log.isDebugEnabled()) {
            _log.debug("messages length >> " + messages.length);
        }

        for (javax.mail.Message emailMessage : messages) {

            if (_log.isDebugEnabled()) {
                _log.debug("emailMessage >> " + emailMessage);
            }

            String from = getEmailAddress(emailMessage.getFrom());
            String recipient = getEmailAddress(emailMessage.getRecipients(javax.mail.Message.RecipientType.TO));

            List<String> recipients = new ArrayList<>();
            recipients.add(recipient);

            if (_log.isDebugEnabled()) {
                _log.debug("From >> " + from);
                _log.debug("Recipient >> " + recipient);
            }

            for (MessageListener messageListener : _messageListenerWrappers.values()) {
                if (messageListener.accept(from, recipients, emailMessage)) {
                    messageListener.deliver(from, recipients, emailMessage);
                }
            }
        }
    }

    protected String getEmailAddress(javax.mail.Address[] addresses) {
        if (addresses == null || addresses.length == 0) {
            return "";
        }

        javax.mail.internet.InternetAddress internetAddress =
                (javax.mail.internet.InternetAddress) addresses[0];

        return internetAddress.getAddress();
    }

    // FIX: HttpURLConnection with connect/read timeouts (used for reading messages)
    private static HttpURLConnection _open(String url) throws IOException {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setConnectTimeout(_connectTimeout());
        conn.setReadTimeout(_readTimeout());
        return conn;
    }

    // FIX: Apache HttpClient with connect/read timeouts (used for token and delete)
    private static CloseableHttpClient _httpClient() {
        RequestConfig requestConfig = RequestConfig.custom()
                .setConnectTimeout(_connectTimeout())
                .setConnectionRequestTimeout(_connectTimeout())
                .setSocketTimeout(_readTimeout())
                .build();

        return HttpClients.custom().setDefaultRequestConfig(requestConfig).build();
    }

    private static int _connectTimeout() {
        return GetterUtil.getInteger(PropsUtil.get("graph.connect.timeout.ms"), DEFAULT_CONNECT_TIMEOUT_MS);
    }

    private static int _readTimeout() {
        return GetterUtil.getInteger(PropsUtil.get("graph.read.timeout.ms"), DEFAULT_READ_TIMEOUT_MS);
    }

    @Reference(
            cardinality = ReferenceCardinality.MULTIPLE,
            policy = ReferencePolicy.DYNAMIC,
            policyOption = ReferencePolicyOption.GREEDY,
            service = MessageListener.class
    )
    protected void addMessageListener(final MessageListener messageListener) {
        MessageListenerWrapper messageListenerWrapper = new MessageListenerWrapper(messageListener);
        _messageListenerWrappers.put(messageListener, messageListenerWrapper);
    }

    protected void removeMessageListener(final MessageListener messageListener) {
        _messageListenerWrappers.remove(messageListener);
    }

    private final Map<MessageListener, MessageListenerWrapper> _messageListenerWrappers =
            new ConcurrentHashMap<>();

    // FIX: Dispatch services used by the startup auto-clear in activate()
    @Reference
    private DispatchLogLocalService _dispatchLogLocalService;

    @Reference
    private DispatchTriggerLocalService _dispatchTriggerLocalService;

    @Override
    public String getName() {
        return "Custom Discussion Graph Notifications";
    }
}
