<%@include file="../init.jsp"%>
<h1 class="portlet-title">
	<span class="portlet-title-text">Brand Use Center: Co-Branding</span>
</h1>

<%@include file="subNavigation.jsp"%>

<portlet:renderURL var="myHistoryPage">
	<portlet:param name="action" value="defaultMyHistory" />
</portlet:renderURL>

<div id="brp_wrapper" class="brp_form">
	<c:choose>
    <c:when test="${empty brandrequest.brandRqstUid}">
       <h1>Co-Branding Partner Form</h1>
    </c:when>	
       <c:otherwise>
       <c:if test="${saveAs ne 'new'}">
       <h1> Modify Co-Branding Request</h1>
       </c:if>
       <c:if test="${saveAs eq 'new'}">
       <h1> Renew Co-Branding Request</h1>
       </c:if>
    </c:otherwise>
	</c:choose>		
	
	<h3>Please complete the fields below about the requested Co-Branding partner.</h3>
	<%-- <a href="${myHistoryPage}">My History</a> --%>
	<span class="note">To view previously approved Co-Branding Partners, go to <a href="reports">My History</a>.
	</span>

	<p class="req">* All fields are required unless noted otherwise.</p>

	<hr />
	<portlet:resourceURL var="getLegalNameSuggestionsURL" id="getLegalNameSuggestions"/>		
	<portlet:resourceURL var="getUserNameSuggestionsURL" id="getUserNameSuggestions"/>
	<portlet:resourceURL var="getUpdatedCategoriesUrl" id="apprSrvcCatsForLe" />
	
	<portlet:actionURL var="saveBrandRequest">
		<portlet:param name="action" value="saveBrandRequest" />
		<portlet:param name="saveAs" value="${saveAs}" />	
	</portlet:actionURL>
	
	<portlet:actionURL var="saveForLaterBrandRequest">
		<portlet:param name="action" value="saveBrandRequest" />
		<portlet:param name="saveForLater" value="saveForLater" />
		<portlet:param name="saveAs" value="${saveAs}" />	
	</portlet:actionURL>

	<portlet:resourceURL var="uploadAttachment" id="uploadBrandRequestAttachment">
				
	</portlet:resourceURL>
	
	
	<portlet:resourceURL var="uploadAttachmentCobrand" id="uploadBrandRequestCobrandAttachment">			
	</portlet:resourceURL>

	<portlet:resourceURL var="deleteAttachment" id="deleteBrandRequestAttachment">		
	</portlet:resourceURL>

	<portlet:renderURL var="discardNewBrandRequest">
<%-- 			<portlet:param name="action" value="discardNewBrandRequest" /> --%>
	</portlet:renderURL>
	
	<portlet:actionURL var="cancelCoBrandRequest">
			<portlet:param name="action" value="discardNewBrandRequest" />
	</portlet:actionURL>

	<portlet:actionURL var="saveForLater">
		<portlet:param name="action" value="saveForLater" />	
		<portlet:param name="saveAs" value="${saveAs}" />	
	</portlet:actionURL>
	
   <!-- ServiceCategory Questions customisation start-->
	<portlet:resourceURL var="serviceCatQuestions" id="serviceCatQuestions">			
	</portlet:resourceURL>
   <!-- ServiceCategory Questions customisation end -->
	
	
	<input type="hidden" id="getUpdatedCategoriesUrl" value="${getUpdatedCategoriesUrl}" />
	<input type="hidden" id="saveForLaterBrandRequest" value="${saveForLaterBrandRequest}" />
	
	<!-- BLWBBCBSAUPGD-135 fix( added onSubmit attribute) -->
	<form:form id="brandRequestForm" modelAttribute="brandrequest" method="post" class="branding" action="${saveBrandRequest}" onsubmit="return false;">
		<form:hidden path="legalNameUid" id="legalNameUid" />
		<c:if test="${isTheUserSME eq true}">
		<!-- Begin This section only available for SME Role, they only can submit the Brand Request on behalf of someone else. -->
		<div class="control-group">
		  <label class="control-label field_header" for="typeAheadUserNameTxt">Search for a different user to submit this request. <liferay-ui:icon-help message="Enter the name of the Plan that has submitted." /></label>
		  <div class="controls">
		  	<form:hidden path="customUserName" id="customUserName" />
		    <form:input path="customFullName"  id="typeAheadUserNameTxt" type="text" placeholder="Type User's last name to start searching." />
		  </div>
		</div>
		<!-- End -->
		</c:if>
	
		<div class="control-group">
		  <label class="control-label field_header" for="legalName">Enter Co-Branding Partner's Legal Name <liferay-ui:icon-help message="Enter the company's legal name, including legal identifiers (i.e. LLC, Inc.)" /></label>
		  <div class="controls">
		      <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="legalName" placeholder="Legal Name" id="legalName" cssClass=""/>
		    <form:errors path="legalName" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="legalName" placeholder="Legal Name" id="legalName" cssClass="" readonly="true"/>
		    </c:if>
		  </div>
		</div>	
		
		<label class="field_header" id="trade_names">Enter Trade Name <liferay-ui:icon-help message="Include other \"Doing Business As\" or DBA names used by the company" /></label>
		<div id="tradeNamesContainer">		
			  <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">		
			<c:if test="${empty brandrequest.tradeNames}">
				<input type="text" name="tradeNames" placeholder="Trade Name" id="tradeNames-1" /> 
			</c:if>
			</c:if>
			<c:if test="${saveAs eq 'new'}">	
			<c:if test="${empty brandrequest.tradeNames}">
				<input type="text" name="tradeNames" placeholder="Trade Name" id="tradeNames-1" readonly="readonly"/> 
			</c:if>
			</c:if>
			
			<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">	
			<c:if test="${not empty brandrequest.tradeNames}">
			<c:forEach items="${brandrequest.tradeNames}" varStatus="i" begin="0" >					
				<input type="text" name="tradeNames" value="${brandrequest.tradeNames[i.index]}" id="${tradeNames-i.index +1}"/>
				<c:if test="${i.index ne fn:length(brandrequest.tradeNames) - 1}">
				<br>
				</c:if>
			</c:forEach>
			</c:if>
			</c:if>
			<c:if test="${saveAs eq 'new'}">
			<c:if test="${not empty brandrequest.tradeNames}">
			<c:forEach items="${brandrequest.tradeNames}" varStatus="i" begin="0" >					
				<input type="text" name="tradeNames" value="${brandrequest.tradeNames[i.index]}" id="${tradeNames-i.index +1}" readonly="readonly"/>
				<c:if test="${i.index ne fn:length(brandrequest.tradeNames) - 1}">
				<br>
				</c:if>
			</c:forEach>
			</c:if>
			</c:if>
		</div>
		<form:errors path="tradeNames" cssClass="errorspanCss" element="div" />
		<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		<a href="#" class="util_link" id="add_trade_name">Add Another</a>
		</c:if>
		<!-- <a href="#" class="util_link" id="remove_trade_name">Remove</a> -->
		<br />
		<br />
		<label class="field_header">Level Type <liferay-ui:icon-help message="Select Level Type" /></label>
		<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		<form:errors path="cobrandReviewType" cssClass="errorspanCss" element="div" />
		<form:select path="cobrandReviewType.cobrandRevwTypUid" id="cobrandRevwTypUid">
			<form:option value="0">Choose One</form:option>
			<form:options itemLabel="cobrandRevwTypNm" itemValue="cobrandRevwTypUid" items="${cobrandReviewTypes}"/>
		</form:select>
		</c:if>
		<c:if test="${saveAs eq 'new'}">	
		<div>
		<form:select path="cobrandReviewType.cobrandRevwTypUid" id="cobrandRevwTypUid" readonly="true" >
		<form:options itemLabel="cobrandRevwTypNm" itemValue="cobrandRevwTypUid" items="${cobrandReviewTypes}"/>
		</form:select>
		</div>
		</c:if>
		<br>
		
		
		 <div id="bcbsasupportID"> 
		 <label class="field_header">BCBSA Support <liferay-ui:icon-help message="For Select Level submissions, BCBSA will complete the requested portion of the analysis, so that your Plan can make the final decision."/></label>
		<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		<form:errors path="coBrandBcbsaSupportList" cssClass="errorspanCss" element="div" />
		<form:select  path="coBrandBcbsaSupportList"  multiple="multiple">
		<c:forEach items="${cobrandbcbsaSupportTypes}" var="cobrandbcbsaSupportType" varStatus="status">
        <c:choose>
            <c:when test="${cobrandbcbsaSupportType.selected}">
                <option value="${cobrandbcbsaSupportType.cOBRANDBCBSASupportUID}" selected="true">${cobrandbcbsaSupportType.coBrandBcbsaSupportDesc}</option>
            </c:when>
            <c:otherwise>
                <option value="${cobrandbcbsaSupportType.cOBRANDBCBSASupportUID}" >${cobrandbcbsaSupportType.coBrandBcbsaSupportDesc}</option>
            </c:otherwise>
        </c:choose> 
        </c:forEach>
		</form:select>
		</c:if>
		<c:if test="${saveAs eq 'new'}">
		<%-- <form:select  path="coBrandBcbsaSupportList"  multiple="multiple" readonly="true" onfocus="this.oldvalue=this.value;this.blur();" onchange="this.value=this.oldvalue;"> --%> 
		<%-- <form:select  path="coBrandBcbsaSupportList"  multiple="multiple" readonly="readonly" disabled="true"> --%>
		<form:select  path="coBrandBcbsaSupportList"  multiple="multiple" readonly="readonly" disabled="true">
		<c:forEach items="${cobrandbcbsaSupportTypes}" var="cobrandbcbsaSupportType" varStatus="status">
        <c:choose>
            <c:when test="${cobrandbcbsaSupportType.selected}">
                <option value="${cobrandbcbsaSupportType.cOBRANDBCBSASupportUID}" selected="selected">${cobrandbcbsaSupportType.coBrandBcbsaSupportDesc}</option>
            </c:when>
            <%-- <c:otherwise>
                <option value="${cobrandbcbsaSupportType.cOBRANDBCBSASupportUID}" >${cobrandbcbsaSupportType.coBrandBcbsaSupportDesc}</option>
            </c:otherwise> --%>
        </c:choose> 
        </c:forEach>
		</form:select>
		</c:if>
		<br>
		
		<br>
		</div>
		
	 
		<%-- <label class="field_header">Co-Branding Renewal <liferay-ui:icon-help message="brp-message"/></label>
		<form:errors path="cobrandRenewalType" cssClass="errorspanCss" element="div" />
		<form:select path="cobrandRenewalType.cobrandRenwTypUid" id="cobrandRenwTypUid">
		<option value="0">Choose One</option>
		<c:forEach items="${cobrandRenewalTypes}" var="cobrandRenewalTypeObj" varStatus="status1">
        
        
        <c:out value="${cobrandRenewalTypeObj.cobrandRenwTypUid}"/>
         <c:out value="${brandrequest.cobrandRenewalType.cobrandRenwTypUid}"/>
        
        <c:choose>
            <c:when test="${cobrandRenewalTypeObj.selected}">
                <option value="${cobrandRenewalTypeObj.cobrandRenwTypUid}" selected="true">${cobrandRenewalTypeObj.cobrandRenwTypNm}</option>
            </c:when>
             
             <c:when test="${cobrandRenewalTypeObj.cobrandRenwTypUid eq brandrequest.cobrandRenewalType.cobrandRenwTypUid}">
                <option value="${cobrandRenewalTypeObj.cobrandRenwTypUid}" selected="true">${cobrandRenewalTypeObj.cobrandRenwTypNm}</option>
            </c:when>
            
            
            <c:otherwise>
                <option value="${cobrandRenewalTypeObj.cobrandRenwTypUid}" >${cobrandRenewalTypeObj.cobrandRenwTypNm}</option>
            </c:otherwise>
        </c:choose> 
    </c:forEach>
		
			
		
		</form:select>
		 --%>
		<br>
	 
	 
	    <div id="cbStrategicRenewRationalDesc">  
		<label class="field_header">Strategic Renewal Rational Description <liferay-ui:icon-help message="brp-message"/></label>
		<form:errors path="cbStrategicRenewRational" cssClass="errorspanCss" element="div" /> 
		<form:textarea path="cbStrategicRenewRational" cssClass="span12" rows="5"></form:textarea>
		<br/>
		</div>
		
		
		
		
		<div class="control-group">
		  <label class="control-label field_header" for="requestedResponseDate">If expedited, please provide a requested response date <liferay-ui:icon-help message="Enter the date a response is needed. Please note: This is not a guarantee, but best efforts." /></label>
		  <div class="controls">
		   <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="requestedResponseDate" placeholder="MM/DD/YYYY" id="requestedResponseDate" cssClass="" />
		    <form:errors path="requestedResponseDate" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="requestedResponseDate" placeholder="MM/DD/YYYY" id="requestedResponseDate" cssClass="" readonly="true"/>
		    </c:if>
		  </div>
		</div>	
		<!-- Co-Branding Partner Form 17-question enhancement start -->
		<input type="hidden" id="serviceCatQuestions" name="<portlet:namespace />serviceCatQuestions" value="${serviceCatQuestions}">
		<input type="hidden" id="serviceCatQuestionsFlag" name="<portlet:namespace />serviceCatQuestionsFlag" value="${empty brandrequest.serviceCatQuestionsFlag ? 'N' : brandrequest.serviceCatQuestionsFlag}">

		<hr />
		<h4>Brand <small>(Questions in this section should be answered for all requests)</small></h4>

		<%-- ===== Q1: Legal name confirmed ===== --%>
		<div class="control-group cb-question" id="cbQ1Block">
			<label class="field_header">Have you confirmed the legal name of this entity (e.g., via secretary of state databases, Dun and Bradstreet, or publicly available government filings) and that any listed trade names are not those of a separately formed legal entity (e.g., has a separate record with a secretary of state or a separate DUNS number)?</label>
			<form:errors path="cbQ1LegalNameCnfrmd" cssClass="errorspanCss" element="div" />
			<label class="radio"><form:radiobutton path="cbQ1LegalNameCnfrmd" value="Y" />&nbsp;Yes</label>
			<label class="radio"><form:radiobutton path="cbQ1LegalNameCnfrmd" value="N" />&nbsp;No</label>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q2: Brands on debit / reward card ===== --%>
		<div class="control-group cb-question" id="cbQ2Block">
			<label class="field_header">Will this solution result in the Brands appearing on a debit card or reward card? If you are unsure, please email Licensure@bcbsa.com for confirmation.</label>
			<form:errors path="cbQ2DebitCardInd" cssClass="errorspanCss" element="div" />
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ2DebitCardInd" value="Y" />&nbsp;Yes</label>
				<div id="cbQ2DateBlock" class="cb-subfield" style="margin-left:24px; display:none;">
					<label>Please provide the date BCBSA confirmed the license agreement for such card was approved, or the date on which the license application was sent to BCBSA: <span class="req" style="color:red;">*</span></label>
					<form:errors path="cbQ2LicenseAgmtDt" cssClass="errorspanCss" element="div" />
					<form:input path="cbQ2LicenseAgmtDt" id="cbQ2LicenseAgmtDt" placeholder="MM/DD/YYYY" />
				</div>
			</div>
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ2DebitCardInd" value="N" />&nbsp;No</label>
				<div id="cbQ2NoInfo" class="cb-subfield" style="margin-left:24px; display:none; font-size:12px; color:#555;">
					No, this solution does not result in the Brands appearing on a debit card or reward card or such cards do not contain the Brands.
				</div>
			</div>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q3: Brands in client list / testimonial ===== --%>
		<div class="control-group cb-question" id="cbQ3Block">
			<label class="field_header">Will this solution result in the Brands appearing in a client list (other than those permitted under chapter 4 of the Brand Regulations) or testimonial on behalf of your Plan?</label>
			<form:errors path="cbQ3ClientListInd" cssClass="errorspanCss" element="div" />
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ3ClientListInd" value="Y" />&nbsp;Yes</label>
				<div id="cbQ3AckBlock" class="cb-subfield" style="margin-left:24px; display:none;">
					<form:errors path="cbQ3ExceptionAckInd" cssClass="errorspanCss" element="div" />
					<label class="checkbox">
						<form:checkbox path="cbQ3ExceptionAckInd" value="Y" />
						Our Plan understands that the Brand Regulations do not permit the Brands to appear in testimonials or client lists on the internet or outside of our service area (unless solely used with other Blue Licensees). We are requesting BCBSA to review an exception for this request.
					</label>
				</div>
			</div>
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ3ClientListInd" value="N" />&nbsp;No</label>
			</div>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q4: Possible Brand misuse located ===== --%>
		<div class="control-group cb-question" id="cbQ4Block">
			<label class="field_header">During your review of this company, did you locate any possible misuse of the Brands that you would like BCBSA to review or assist with resolving?</label>
			<form:errors path="cbQ4BrandMisuseInd" cssClass="errorspanCss" element="div" />
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ4BrandMisuseInd" value="Y" />&nbsp;Yes</label>
				<div id="cbQ4Subfields" class="cb-subfield" style="margin-left:24px; display:none;">
					<label>Please provide links to the possible misuse: <span class="req" style="color:red;">*</span></label>
					<form:errors path="cbQ4MisuseLinksTxt" cssClass="errorspanCss" element="div" />
					<form:textarea path="cbQ4MisuseLinksTxt" id="cbQ4MisuseLinksTxt" cssClass="span12" rows="3"></form:textarea>
					<label>Please provide a contact name and email address for a contact at the company we can reach out to in order to resolve this matter: <span class="req" style="color:red;">*</span></label>
					<form:errors path="cbQ4MisuseContactTxt" cssClass="errorspanCss" element="div" />
					<form:textarea path="cbQ4MisuseContactTxt" id="cbQ4MisuseContactTxt" cssClass="span12" rows="3"></form:textarea>
					<form:errors path="cbQ4MisuseAckInd" cssClass="errorspanCss" element="div" />
					<label class="checkbox">
						<form:checkbox path="cbQ4MisuseAckInd" value="Y" />
						Our Plan understands that BCBSA will review the report and take action, if required. If misuse is confirmed by BCBSA, we understand the request will not be processed until such misuse is resolved.
					</label>
				</div>
			</div>
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ4BrandMisuseInd" value="N" />&nbsp;No</label>
			</div>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q5: Name / logo / slogan infringement ===== --%>
		<div class="control-group cb-question" id="cbQ5Block">
			<label class="field_header">Does the company's name, logo or slogan include elements (e.g., a blue cross or shield design, the word "blue," etc.) that is likely to infringe on or impact the goodwill of the Brands?</label>
			<form:errors path="cbQ5NameLogoInfrngInd" cssClass="errorspanCss" element="div" />
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ5NameLogoInfrngInd" value="Y" />&nbsp;Yes</label>
				<div id="cbQ5Subfields" class="cb-subfield" style="margin-left:24px; display:none;">
					<label>Please provide a link showing the name, logo or slogan: <span class="req" style="color:red;">*</span></label>
					<form:errors path="cbQ5InfrngLinksTxt" cssClass="errorspanCss" element="div" />
					<form:textarea path="cbQ5InfrngLinksTxt" id="cbQ5InfrngLinksTxt" cssClass="span12" rows="3"></form:textarea>
					<label>Please provide a contact name and email address for a contact at the company we can reach out to in order to resolve this matter: <span class="req" style="color:red;">*</span></label>
					<form:errors path="cbQ5InfrngContactTxt" cssClass="errorspanCss" element="div" />
					<form:textarea path="cbQ5InfrngContactTxt" id="cbQ5InfrngContactTxt" cssClass="span12" rows="3"></form:textarea>
					<form:errors path="cbQ5InfrngAckInd" cssClass="errorspanCss" element="div" />
					<label class="checkbox">
						<form:checkbox path="cbQ5InfrngAckInd" value="Y" />
						Our Plan understands that BCBSA will review the report and take action, if required. If the report is confirmed by BCBSA, we understand the request will not be processed until such misuse is resolved.
					</label>
				</div>
			</div>
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ5NameLogoInfrngInd" value="N" />&nbsp;No</label>
			</div>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q6: Financial stability ===== --%>
		<div class="control-group cb-question" id="cbQ6Block">
			<label class="field_header">To the best of your knowledge, is the company financially stable as outlined in the Brand Regulations?</label>
			<form:errors path="cbQ6FinlStableInd" cssClass="errorspanCss" element="div" />
			<label class="radio"><form:radiobutton path="cbQ6FinlStableInd" value="Y" />&nbsp;Yes</label>
			<label class="radio"><form:radiobutton path="cbQ6FinlStableInd" value="N" />&nbsp;No</label>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q7: Felony ===== --%>
		<div class="control-group cb-question" id="cbQ7Block">
			<label class="field_header">To the best of your knowledge, has the company been convicted of a felony within the past three years?</label>
			<form:errors path="cbQ7FelonyInd" cssClass="errorspanCss" element="div" />
			<label class="radio"><form:radiobutton path="cbQ7FelonyInd" value="Y" />&nbsp;Yes</label>
			<label class="radio"><form:radiobutton path="cbQ7FelonyInd" value="N" />&nbsp;No</label>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q8: Not on disapproved list ===== --%>
		<div class="control-group cb-question" id="cbQ8Block">
			<label class="field_header">Have you confirmed that the company is not on one of the <a href="https://bluewebportal.bcbs.com/resources/brand-use/brand-use-portal/reports" target="_blank">lists</a> (e.g., brand conflict, disapproved, national competitor or primary brand of a national competitor) which prevents the company from co-branding?</label>
			<form:errors path="cbQ8NotOnListInd" cssClass="errorspanCss" element="div" />
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ8NotOnListInd" value="Y" />&nbsp;Yes, the company does not appear on any of the applicable lists.</label>
			</div>
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ8NotOnListInd" value="E" />&nbsp;Yes, the company appears on one or more lists, but they are solely providing PBM services or an exception has been documented with BCBSA.</label>
			</div>
			<div class="cb-radio-row">
				<label class="radio"><form:radiobutton path="cbQ8NotOnListInd" value="N" />&nbsp;No</label>
			</div>
			<hr class="cb-question-sep" />
		</div>

		<%-- ===== Q9: Reputation ===== --%>
		<div class="control-group cb-question" id="cbQ9Block">
			<label class="field_header">In your reasonable business judgement, does the company have a reputation that would dilute or tarnish the value of the Brands?</label>
			<form:errors path="cbQ9ReputationInd" cssClass="errorspanCss" element="div" />
			<label class="radio"><form:radiobutton path="cbQ9ReputationInd" value="Y" />&nbsp;Yes</label>
			<label class="radio"><form:radiobutton path="cbQ9ReputationInd" value="N" />&nbsp;No</label>
			<hr class="cb-question-sep" />
		</div>

		<h4>
			Choose Co-Branding Service Categories <liferay-ui:icon-help message="Click all categories that the cobranding partner will offer." />
		</h4>
		<form:errors path="brandRqstServiceCategories" cssClass="errorspanCss" element="div" />
		<div class="row-fluid">Please hover over the <liferay-ui:icon-help message="" /> next to the category to view the definition.</div>
		<span class="bold">Service categories in blue have been previously approved for the selected company.</span>
			
		<div class="row-fluid service_categories" id="serviceCategoriesDiv">
		<c:forEach items="${serviceCategories}" var="serviceCategory" varStatus="counter">			
			<div class="col-md-6">
			
			<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
				<c:if test="${serviceCategory.srvcCtgyNm ne 'Other'}">
					<c:set var="srvcCtgyUidTxt" value="${','}${serviceCategory.srvcCtgyUid}${','}"/>
					<input type="checkbox" name="brandRqstServiceCategories[${counter.index}].srvcCtgyUid" value="${serviceCategory.srvcCtgyUid}" <c:if test="${fn:contains(brandrequest.brandRqstServiceCategoriesCsv, srvcCtgyUidTxt)}">checked</c:if> > ${serviceCategory.srvcCtgyNm} <liferay-ui:icon-help message="${serviceCategory.srvcCtgyDefn}" />
				</c:if>
				</c:if>
				
				<c:if test="${saveAs eq 'new'}">
				<c:if test="${serviceCategory.srvcCtgyNm ne 'Other'}">
					<c:set var="srvcCtgyUidTxt" value="${','}${serviceCategory.srvcCtgyUid}${','}"/>
				<input type="checkbox" name="brandRqstServiceCategories[${counter.index}].srvcCtgyUid" value="${serviceCategory.srvcCtgyUid}" 
				<c:if test="${fn:contains(brandrequest.brandRqstServiceCategoriesCsv, srvcCtgyUidTxt)}">checked</c:if> onclick="return false"> ${serviceCategory.srvcCtgyNm} <liferay-ui:icon-help message="${serviceCategory.srvcCtgyDefn}" />
				</c:if>
				</c:if>
				
				
				
				<c:if test="${serviceCategory.srvcCtgyNm eq 'Other'}">
				<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
					<input type="checkbox" id="otherCheckbox" name="brandRqstServiceCategories[${counter.index}].srvcCtgyUid" value="${serviceCategory.srvcCtgyUid}" <c:if test="${fn:contains(brandrequest.brandRqstServiceCategoriesCsv, serviceCategory.srvcCtgyUid)}">checked</c:if> >	${serviceCategory.srvcCtgyNm} <liferay-ui:icon-help message="${serviceCategory.srvcCtgyDefn}" />
				</c:if>	
				<c:if test="${saveAs eq 'new'}">
				    <input type="checkbox" id="otherCheckbox" name="brandRqstServiceCategories[${counter.index}].srvcCtgyUid" value="${serviceCategory.srvcCtgyUid}" <c:if test="${fn:contains(brandrequest.brandRqstServiceCategoriesCsv, serviceCategory.srvcCtgyUid)}">checked</c:if> onclick="return false">	${serviceCategory.srvcCtgyNm} <liferay-ui:icon-help message="${serviceCategory.srvcCtgyDefn}" />
				</c:if>
					<br>
					<p class="other_service_category">
						Don't see what you need in the selection above? 
						<br>Type a service category that you need below. 
					</p>	
					<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">		
					<input style="margin-left:16px !important;" type="text" name="othSrvcCtgyNm" id="otherServiceCategoryId" value="${brandrequest.othSrvcCtgyNm}" />
					</c:if>
					<c:if test="${saveAs eq 'new'}">		
					<input style="margin-left:16px !important;" type="text" name="othSrvcCtgyNm" id="otherServiceCategoryId" value="${brandrequest.othSrvcCtgyNm}" readonly="readonly" />
					</c:if>
				</c:if>					
			</div>			
		</c:forEach>
		</div>
		<div class="clearfix"></div>

		<!-- ===== Q10-Q17: Inter-Plan Policy questions (shown only when triggered by service category) ===== -->
		<div id="serviceCategoryQuestions" style="display:none;">
			<hr />
			<h4>Inter-Plan Policy <liferay-ui:icon-help message="The following questions appear when one or more Inter-Plan Policy service categories are selected." /></h4>

			<%-- ===== Q10: Inter-Plan Executive ===== --%>
			<div class="control-group cb-question" id="cbQ10Block">
				<label class="field_header">Please provide the name of the Inter-Plan Executive or member of your Plan's Inter-Plan team who reviewed this request for compliance with Inter-Plan Policies and Provisions. <span class="req" style="color:red;">*</span></label>
				<form:errors path="cbQ10InterPlanExecTxt" cssClass="errorspanCss" element="div" />
				<form:textarea path="cbQ10InterPlanExecTxt" id="cbQ10InterPlanExecTxt" cssClass="span12" rows="3"></form:textarea>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q11: Carveout / Claim / Other ===== --%>
			<div class="control-group cb-question" id="cbQ11Block">
				<label class="field_header">Do these services generate a claim against the member's Blue benefits or is this a carveout? For purposes of this request, carveout means the benefits are not Blue, the member would not present their BCBS ID card when seeking services, and there are no claims filed/processed against the member's Blue benefits. <span class="req" style="color:red;">*</span></label>
				<form:errors path="serviceCategoryBlueBenefit" cssClass="errorspanCss" element="div" />
				<label class="radio"><form:radiobutton path="serviceCategoryBlueBenefit" value="CARVEOUT" />&nbsp;Carveout</label>
				<label class="radio"><form:radiobutton path="serviceCategoryBlueBenefit" value="CLAIM" />&nbsp;Generates a claim against the member's Blue benefits</label>
				<div class="cb-radio-row">
					<label class="radio"><form:radiobutton path="serviceCategoryBlueBenefit" value="OTHER" />&nbsp;Other (please describe)</label>
					<div id="cbQ11OtherBlock" class="cb-subfield" style="margin-left:24px; display:none;">
						<label>Please describe: <span class="req" style="color:red;">*</span></label>
						<form:errors path="cbQ11OtherTxt" cssClass="errorspanCss" element="div" />
						<form:textarea path="cbQ11OtherTxt" id="cbQ11OtherTxt" cssClass="span12" rows="3"></form:textarea>
					</div>
				</div>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q12: Clinical telehealth ===== --%>
			<div class="control-group cb-question" id="cbQ12Block" style="display:none;">
				<label class="field_header">If the services generate a claim against the member's Blue benefits, is this a clinical telehealth service or solution (e.g., behavioral health or primary care)?</label>
				<form:errors path="cbQ12TelehealthSvcInd" cssClass="errorspanCss" element="div" />
				<label class="radio"><form:radiobutton path="cbQ12TelehealthSvcInd" value="Y" />&nbsp;Yes</label>
				<label class="radio"><form:radiobutton path="cbQ12TelehealthSvcInd" value="N" />&nbsp;No</label>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q13: Virtual only ===== --%>
			<div class="control-group cb-question" id="cbQ13Block" style="display:none;">
				<label class="field_header">If this is a clinical telehealth service or solution (e.g., behavioral health or primary care), are the services virtual only?</label>
				<form:errors path="cbQ13VirtualOnlyInd" cssClass="errorspanCss" element="div" />
				<label class="radio"><form:radiobutton path="cbQ13VirtualOnlyInd" value="Y" />&nbsp;Yes, this is a virtual only telehealth service or solution.</label>
				<label class="radio"><form:radiobutton path="cbQ13VirtualOnlyInd" value="N" />&nbsp;No, the service or solution includes the option for in-person services.</label>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q14: Available outside Plan service area ===== --%>
			<div class="control-group cb-question" id="cbQ14Block" style="display:none;">
				<label class="field_header">Is this program/service available to your national account members that reside outside of your Plan's service area?</label>
				<form:errors path="serviceCategoryNationalAccountMember" cssClass="errorspanCss" element="div" />
				<label class="radio"><form:radiobutton path="serviceCategoryNationalAccountMember" value="Y" />&nbsp;Yes</label>
				<label class="radio"><form:radiobutton path="serviceCategoryNationalAccountMember" value="N" />&nbsp;No</label>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q15: What do services entail ===== --%>
			<div class="control-group cb-question" id="cbQ15Block" style="display:none;">
				<label class="field_header">What do the services entail? Please provide as much detail as possible.</label>
				<form:errors path="serviceCategoryServiceEntail" cssClass="errorspanCss" element="div" />
				<form:textarea path="serviceCategoryServiceEntail" id="serviceCategoryServiceEntail" cssClass="span12" rows="3"></form:textarea>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q16: Outreach to providers ===== --%>
			<div class="control-group cb-question" id="cbQ16Block" style="display:none;">
				<label class="field_header">Does this solution include outreach to providers outside of your service area?</label>
				<form:errors path="cbQ16ProviderOutreachInd" cssClass="errorspanCss" element="div" />
				<label class="radio"><form:radiobutton path="cbQ16ProviderOutreachInd" value="Y" />&nbsp;Yes</label>
				<label class="radio"><form:radiobutton path="cbQ16ProviderOutreachInd" value="N" />&nbsp;No</label>
				<hr class="cb-question-sep" />
			</div>

			<%-- ===== Q17: Provider outreach detail (standalone, shown when Q16=Yes) ===== --%>
			<div class="control-group cb-question" id="cbQ17Block" style="display:none;">
				<label class="field_header">If this solution includes outreach to providers outside of your service area, what does this provider outreach entail? Please provide as much detail as possible. <span class="req" style="color:red;">*</span></label>
				<form:errors path="cbQ17ProviderOutreachTxt" cssClass="errorspanCss" element="div" />
				<form:textarea path="cbQ17ProviderOutreachTxt" id="cbQ17ProviderOutreachTxt" cssClass="span12" rows="3"></form:textarea>
				<hr class="cb-question-sep" />
			</div>

		</div>
		<!-- Co-Branding Partner Form 17-question enhancement end -->
		
		<hr style="display: none;"/>
		<div>
		<label class="field_header">State of Incorporation <liferay-ui:icon-help message="Enter State of Incorporation" /></label>
		<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">	
		<form:errors path="stateOfIncorporation" cssClass="errorspanCss" element="div" />
		<form:select path="stateOfIncorporation.usStateCd" cssClass="" id="stateIncorp">
			<form:option value="0">Choose a State</form:option>
			<form:options itemLabel="usStateNm" itemValue="usStateCd" items="${usStates}"/>
		</form:select>
		</c:if>
		<c:if test="${saveAs eq 'new'}">	
		<form:select path="stateOfIncorporation.usStateCd" cssClass="" id="stateIncorp" readonly="true">
			<form:options itemLabel="usStateNm" itemValue="usStateCd" items="${usStates1}"/>
		</form:select>
		</c:if>
		</div>
		
		<br />
		<hr />
		<h4>Headquarters Address</h4>
		<div class="control-group">
		  <label class="control-label field_header" for="address1">Enter Street Address <liferay-ui:icon-help message="Enter Street Address for Headquarters" /></label>
		  <div class="controls">
		    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="address1" placeholder="Address" cssClass="" id="address1"/>
		    <form:errors path="address1" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="address1" placeholder="Address" cssClass="" id="address1" readonly="true"/>
		    </c:if>  
		  </div>
		</div>			

		<div class="control-group">
		  <label class="control-label field_header" for="address2">Enter Street Address 2 <liferay-ui:icon-help message="Enter Street Address for Headquarters" /></label>
		  <div class="controls">
		    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="address2" placeholder="Address" cssClass="" id="address2"/>
		    <form:errors path="address2" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="address2" placeholder="Address" cssClass="" id="address2" readonly="true"/>
		    </c:if>
		  </div>
		</div>	

		<div class="control-group">
		  <label class="control-label field_header" for="city">Enter City <liferay-ui:icon-help message="Enter City of Headquaters" /></label>
		  <div class="controls">
		    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="city" placeholder="City" cssClass="" id="city"/>
		    <form:errors path="city" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="city" placeholder="City" cssClass="" id="city" readonly="true"/>
		    </c:if>  
		  </div>
		</div>

		<table>
			<tr>
				<td class="no_left_padding">
					<label class="control-label field_header" for="usStateCd">Choose State <liferay-ui:icon-help message="Choose State of Headquarters" /></label> 
					<form:errors path="state" cssClass="errorspanCss" element="div" />
					<div class="controls">
					<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
					<form:select path="state.usStateCd" cssClass="" id="usStateCd">
						<form:option value="0">---</form:option>
						<form:options itemLabel="usStateNm" itemValue="usStateCd" items="${usStates}"/>
					</form:select>
					</c:if>
					<c:if test="${saveAs eq 'new'}">
					<form:select path="state.usStateCd" cssClass="" id="usStateCd" readonly="true">
						<form:options itemLabel="usStateNm" itemValue="usStateCd" items="${usStates}"/>
					</form:select>
					</c:if>
					</div>
				</td>
				<td>
					<div class="control-group">
					  <label class="control-label field_header" for="zipCode">Enter ZIP <liferay-ui:icon-help message="Enter ZIP code" /></label>
					  <form:errors path="zipCode" cssClass="errorspanCss" element="div" />
					  <div class="controls">
					  	<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
					  	<form:input path="zipCode" placeholder="ZIP" cssClass="" id="zipCode"/>
					  	</c:if>
					  	<c:if test="${saveAs eq 'new'}">
					  	<form:input path="zipCode" placeholder="ZIP" cssClass="" id="zipCode" readonly="true"/>
					  	</c:if>
					  </div>
					</div>				
				</td>
			</tr>
		</table>
		<br />
		<div class="control-group">
		  <label class="control-label field_header" for="phoneNum">Enter Phone <liferay-ui:icon-help message="Enter Phone Number" /></label>
		  <div class="controls">
		    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="phone" placeholder="Phone" id="phoneNum"/>
		    <form:errors path="phone" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="phone" placeholder="Phone" id="phoneNum" readonly="true"/>
		    </c:if>
		  </div>
		</div>			
		<hr />
		<div class="control-group">
		  <label class="control-label field_header" for="dunsNum">Enter D&B Number (Optional) <liferay-ui:icon-help message="Provide the Dun & Bradstreet number, if known. It may allow for faster processing." /></label>
		  <div class="controls">
		    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="dandbNumber" placeholder="D&B Number" id="dunsNum"/>
		    <form:errors path="dandbNumber" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="dandbNumber" placeholder="D&B Number" id="dunsNum" readonly="true"/>
		    </c:if>
		  </div>
		</div>			

		<div class="control-group">
		  <label class="control-label field_header" for="webSite">Enter Company Website <liferay-ui:icon-help message="Enter Company Website of company" /></label>
		  <div class="controls">
		    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		    <form:input path="companyWebSite" placeholder="Company Website" id="webSite"/>
		    <form:errors path="companyWebSite" cssClass="help-inline red-text" element="span" />
		    </c:if>
		    <c:if test="${saveAs eq 'new'}">
		    <form:input path="companyWebSite" placeholder="Company Website" id="webSite" readonly="true"/>
		    </c:if>    
		  </div>
		</div>
		<h4>
			Is the requested company an Unlicensed Affiliate?
			<liferay-ui:icon-help message="Does a BCBS Plan (s) have ownership? If unsure, click \"No\"." />
		</h4>
		<form:errors path="isUnlicensed" cssClass="errorspanCss" element="div" />
		<table>
			<tr>
				<td>
				    <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
					<label><form:radiobutton path="isUnlicensed" value="Yes" /> Yes</label> 
					<label><form:radiobutton path="isUnlicensed" value="No" /> No</label>
					</c:if>
					<c:if test="${saveAs eq 'new'}">
					<%-- <label><form:radiobutton id="rad1" path="isUnlicensed" value="Yes" onclick="return false;" style="display:none;"/> Yes</label> 
					<label><form:radiobutton id="rad2" path="isUnlicensed" value="No" onclick="return false;" style="display:none;"/> No</label> --%>
					<c:if test="${brandrequest.isUnlicensed eq 'Yes'}">
					<label><form:radiobutton id="rad1" path="isUnlicensed" value="Yes"/>Yes</label> 
					<label><form:radiobutton id="rad2" path="isUnlicensed" value="No" disabled="true"/> No</label>
					</c:if>
					<c:if test="${brandrequest.isUnlicensed eq 'No'}">
					<label><form:radiobutton id="rad1" path="isUnlicensed" value="Yes" disabled="true"/>Yes</label> 
					<label><form:radiobutton id="rad2" path="isUnlicensed" value="No"/> No</label>
					</c:if>
					</c:if>
				</td>
				<td>
					<label class="field_header">Enter Plan Name <liferay-ui:icon-help message="Enter Plan's Name that have ownership, even if multiple" /></label> 
					<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
					<form:select path="plan.planCd" id="planCodes">
						<form:option value="0">Choose One</form:option>
						<form:options items="${plans}" itemLabel="planNm" itemValue="planCd" />
					</form:select>
					</c:if>
					<c:if test="${saveAs eq 'new'}">	
					<form:select path="plan.planCd" id="planCodes" readonly="true">
					    <c:if test="${empty plans}">
						<form:option value="0">Choose One</form:option>
						</c:if>
						<form:options items="${plans}" itemLabel="planNm" itemValue="planCd" />
					</form:select>
					</c:if>
				</td>
			</tr>
		</table>
		<br />
		<label class="field_header">Choose Partnership Type <liferay-ui:icon-help message="Who has the partnership? 
1) Hired by Plan (Contracted by the Plan),
2) Hired by Account (Contracted by the Account), or
3) Both (Contracted by the Plan and the Account)" /></label>
        <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		<form:errors path="businessType" cssClass="errorspanCss" element="div" />
		<form:select path="businessType.busTypCd" id="businessType">
			<form:option value="0">Choose One</form:option>
			<form:options items="${businessTypes}" itemLabel="busTypDesc" itemValue="busTypCd"/>
		</form:select>
		</c:if>
		<c:if test="${saveAs eq 'new'}">
		<form:select path="businessType.busTypCd" id="businessType" readonly="true"> 
			<form:options items="${businessTypes}" itemLabel="busTypDesc" itemValue="busTypCd"/>
		</form:select>
		</c:if>
		<br />
		<%-- Group Account Type field removed - 17-question enhancement --%>
		<h4>
			Is the company a Third Party Administrator (TPA)?
			<liferay-ui:icon-help message="Is the company a Third Party Administrator?" />
		</h4>
		<form:errors path="isTpa" cssClass="errorspanCss" element="div" />
		<c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">
		<label><form:radiobutton path="isTpa" value="Yes" /> Yes</label>
		<label><form:radiobutton path="isTpa" value="No" /> No</label>
		</c:if>
		<c:if test="${saveAs eq 'new'}">
		<c:if test="${brandrequest.isTpa eq 'Yes'}">
		<label><form:radiobutton path="isTpa" value="Yes" /> Yes</label>
		<label><form:radiobutton path="isTpa" value="No" disabled="true"/> No</label>
		</c:if>
		<c:if test="${brandrequest.isTpa eq 'No'}">
		<label><form:radiobutton path="isTpa" value="Yes" disabled="true"/> Yes</label>
		<label><form:radiobutton path="isTpa" value="No" /> No</label>
		</c:if>
		</c:if>
		<br />
		<hr />
		<label class="field_header">Describe where and how co-branding will appear. <liferay-ui:icon-help message="Include specific details about the location of cobranding, where and how cobranding will appear." /></label>
		<label>(Please also include any additional comments that will help in processing your request)</label>
		<form:errors path="coBrandDescription" cssClass="errorspanCss" element="div" /> 
		<form:textarea path="coBrandDescription" cssClass="span12" rows="5"></form:textarea>
		<br />

		<a href="#" class="upload_link"><label class="field_header">Upload Attachment <span>+</span></label></a>
		<br />
		
		<div id="cobrandUserFile">
		<%-- <label class="field_header">Cobranding Upload. <liferay-ui:icon-help message="Include specific details about the location of cobranding, where and how cobranding will appear." /></label>
		<label>(Please also include any additional comments that will help in processing your request)</label>
		<form:errors path="coBrandFileDescription" cssClass="errorspanCss" element="div" /> 
		<form:textarea path="coBrandFileDescription" cssClass="span12" rows="5"></form:textarea> --%>
		<br />
		<a href="#" class="cobrand_upload_link"><label class="field_header">Upload Co-Branding Samples Attachment <span>+</span></label></a>
		<br />
		</div>
		
		<div id="strategicUserFile">
		<label class="field_header">Please provide the decision factors in which your Plan concluded this partner qualifies at the Strategic Level.</label>
		<form:errors path="cbStrategicDecisionFact" cssClass="errorspanCss" element="div" /> 
		<form:textarea path="cbStrategicDecisionFact" cssClass="span12" rows="5"></form:textarea>
		<br />
		<a href="#" class="upload_stategic_link"><label class="field_header">Upload Attachment <span>+</span></label></a>
		</div>
		<hr />
		<br />
		
		<div id="attachments">					
			<table id="attachment_table" class="table table-striped table-bordered">
				<tr>
					<th>File Name</th>
					<th>Description</th>
					<th>Actions</th>
					<!-- <th>Type</th>
					<th>FileType</th>  -->
					<!-- <th>type</th> -->
				</tr>
				<%-- <c:if test="${saveAs ne 'new' || empty brandrequest.brandRqstUid}">		 --%>			
				<c:forEach var="attachment" items="${brandrequest.attachmentList}" varStatus="status">
					<tr id="${attachment.fileId}">
						<td>
							<input type="hidden" name="<portlet:namespace />attachmentList[${status.index}].fileName" value="${attachment.fileName}"/>
							<input type="hidden" name="<portlet:namespace />attachmentList[${status.index}].fileDescription" value="${attachment.fileDescription}"/>
							<input type="hidden" name="<portlet:namespace />attachmentList[${status.index}].fileId" value="${attachment.fileId}"/>
							<input type="hidden" name="<portlet:namespace />attachmentList[${status.index}].type" value="${attachment.type}"/>
							<input type="hidden" name="<portlet:namespace />attachmentList[${status.index}].fileType" value="${attachment.fileType}"/>
							
							<c:out value="${attachment.fileName}" />
						</td>
						<td>
							<c:out value="${attachment.fileDescription}" />
						</td>
						
						<td>
							<a href="#" class="util_link confirm_delete">Delete</a>
						</td>
						
						<%-- <td>
							<c:out value="${attachment.type}" />
						</td>
						
					    <td>
							<c:out value="${attachment.fileType}" />
						</td>  --%>
						
					</tr>
				</c:forEach>
				<%-- </c:if> --%>					
			</table>
		</div>
		<hr />
		<input type="hidden" id="getLegalNameSuggestionsURL" name="<portlet:namespace />getLegalNameSuggestionsURL" value="${getLegalNameSuggestionsURL}">
		<input type="hidden" id="getUserNameSuggestionsURL" value="${getUserNameSuggestionsURL}">
		<input type="hidden" name="brandRqstUid" value="${brandrequest.brandRqstUid}">
		<!-- 
		<input type="submit" id="discardRequestBtn" value="Discard Request"
			class="button"/>-->
		<!-- TODO: style this as a button (not sure how to do this) -->
		<div class="row-fluid">
			<c:if test="${empty brandrequest.brandRqstUid}">
				<div class="col-md-6">
					<input type="button" id="saveForLaterBtn" value="Save For Later" class="btn" name="saveForLater" onclick="javascript:saveForLaterCobrandRequest()"/>
					<a href="${discardNewBrandRequest}" class="button blue_button btn" onclick="coBrandDiscardReqClick(event);" id="coBrandDiscardReq">Discard Request</a>			
				</div>
			</c:if>
			<c:if test="${not empty brandrequest.brandRqstUid}">
			<div class="col-md-6">
				<a class="btn" href="${cancelCoBrandRequest}" >Cancel</a>
				<a href="${discardNewBrandRequest}" class="button blue_button btn" onclick="coBrandDiscardReqClick(event);" id="coBrandDiscardReq">Discard Request</a>			
			</div>
			</c:if>
			 <c:if test="${saveAs ne 'new'}">
			<div class="col-md-6 text-right">
				<input type="button" id="applyRequestBtn" value="Apply &amp; Review Request" class="button blue_button" onclick="javascript:submitNewCobrandRequest()"/>
			</div>
			</c:if>
			
			<c:if test="${saveAs eq 'new'}">
			<div class="col-md-6 text-right">
				<input type="button" id="applyRequestBtn" value="Renew Request" class="button blue_button" onclick="javascript:submitNewCobrandRequest()"/>
			</div>
			</c:if>
		</div>
	</form:form>
</div>


<div id="attachment-dialog" title="Upload Attachment" class="hiddenDefault">
	<div class="textLabel">Attachments must be uploaded one at a time.</div>
	<div id="attachment-error" class="error"></div>	
	<form name="myUploadForm" id="myUploadForm" method="post" action="${uploadAttachment}" enctype="multipart/form-data">
	<div id="result"></div>		
	<input id="fileData" type="file" name="<portlet:namespace />file"> 		
	<label for="description">Description (Optional)</label>		
	<textarea name= "<portlet:namespace />fileDescription" id="fileDescription" rows="4" cols="50"></textarea>
	</form>
</div>


<div id="attachment-stategic-dialog" title="Upload Attachment" class="hiddenDefault">
	<div class="textLabel">Attachments must be uploaded one at a time.</div>
	<div id="attachment-error" class="error"></div>	
	<form name="mystategicUploadForm" id="mystategicUploadForm" method="post" action="${uploadAttachment}" enctype="multipart/form-data">
	<div id="result"></div>		
	<input type="hidden" value="3" name="fileType" >
	<input id="stategicfileData" type="file" name="<portlet:namespace />file"> 		
	<label for="description">Description (Optional)</label>		
	<textarea name= "<portlet:namespace />fileDescription" id="stategicfileDescription" rows="4" cols="50"></textarea>
	</form>
</div>



<%-- ===== Co-Branding Partner Form 17-question pop-up blocker dialogs ===== --%>
<div id="cbQ1BlockerDialog" title="Co-Branding Request" class="hiddenDefault">
	Co-branding requests should use the legal name of the co-branding partner. Separate requests are required for each unlicensed entity appearing in co-branded communications.
</div>

<div id="cbQ6BlockerDialog" title="Co-Branding Request" class="hiddenDefault">
	Co-branding partners are required to be financially stable per the Brand Regulations.
</div>

<div id="cbQ7BlockerDialog" title="Co-Branding Request" class="hiddenDefault">
	Co-branding partners cannot have been convicted of a felony in the past three years.
</div>

<div id="cbQ9BlockerDialog" title="Co-Branding Request" class="hiddenDefault">
	Co-branding partners may not have a reputation that would dilute or tarnish the value of the Brands.
</div>

<div id="cbQ8BlockerDialog" title="Co-Branding Request" class="hiddenDefault">
	Unless solely for PBM services or an exception has been documented, a co-branding partner may not appear on the cited lists. Please confirm.
</div>

<div id="attachment-cobrand-dialog" title="Upload Cobrand Attachment" class="hiddenDefault">
	<div class="textLabel">Attachments must be uploaded one at a time.</div>
	<div id="attachment-error" class="error"></div>	
	<form name="myCobrandUploadForm" id="myCobrandUploadForm" method="post" action="${uploadAttachmentCobrand}" enctype="multipart/form-data">
	<div id="result"></div>		
	<input id="cobrandfileData" type="file" name="<portlet:namespace />file"> 		
	<label for="description">Description (Optional)</label>		
	<textarea name= "<portlet:namespace />cobrandfileDescription" id="cobrandfileDescription" rows="4" cols="50"></textarea>
	</form>
</div>


<div id="delete-confirmation" title="Delete Attachment?" class="hiddenDefault">	
  Are you sure you would like to delete this attachment?
</div>



<div id="coBrandDiscardReqDialog" title="Discard Co-Branding Request Confirmation" class="hiddenDefault">
  Would you like to discard the request before submitting it?
</div>




<form name="attachmentDeleteForm" id="attachmentDeleteForm" method="post" action="${deleteAttachment}" enctype="multipart/form-data">
	<input id="fileid-to-delete" type="hidden" name="<portlet:namespace />fileIdToDelete"/>
</form>

<script type="text/javascript" src="<%=request.getContextPath()%>/js/newCobrand.js"></script>
<!-- BLWBBCBSAUPGD-135 fix( included javascript) -->

<script type="text/javascript" src="<%=request.getContextPath()%>/js/main.js"></script>
