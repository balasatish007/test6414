#!/usr/bin/perl -w
use lib "/home/liferay/pv_backup/lib64/perl15";
use lib "/home/liferay/pv_backup/share/perl15";
use strict;
$| = 1;
use sigtrap qw(die untrapped);

use DBI;
use DBD::ODBC;
use Data::Dump::Streamer;
  
use URI;
use URI::Escape;
use constant DAYS => 86400;     # for specifications
use lib "/opt/liferaysharepv/monthly_reports";
use bcbsa_reports;
use IO::Handle;
use LWP::UserAgent;
#use WWW:Mechanize();
#use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Request;
use IO::Socket::SSL qw();

use WWW::Mechanize qw();

autoflush STDOUT 1;

## ===========================================================================
## OKTA CREDENTIALS -- fill these in once.  The script now fetches its own
## sessionToken at run time, so there is no longer any need to curl for a
## token and paste it in with vi before every run.
##   chmod 600 this file after filling in the password.
## ===========================================================================
my $okta_user     = 'bwreportsuser@bcbs.com';
my $okta_pass     = '';          ## <-- PUT THE PASSWORD HERE
my $okta_authnurl = 'https://bcbs-system-sp.okta.com/api/v1/authn';
my $okta_ssobase  = 'https://bcbs-system-sp.okta.com/app/bcbs-system-sp_siteminderfederationpoc_2/exksougizeCi7H61S696/sso/saml?onetimetoken=';

## Fallback: if you would rather paste a token by hand, put it here and leave
## $okta_pass empty.  If both are set, the password wins.
my $okta_manual_token = '';

my $oktaspurl = '';   ## built below, once we have a live sessionToken

sub okta_session_token {
   my $ua = LWP::UserAgent->new(
      ssl_opts => { SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
                    verify_hostname => 0 },
      timeout  => 60,
   );
   my $u = $okta_user; my $p = $okta_pass;
   for ($u, $p) { s/\\/\\\\/g; s/"/\\"/g; }
   my $json = '{"username":"'.$u.'","password":"'.$p.'",'
            . '"options":{"multiOptionalFactorEnroll":false,'
            . '"warnBeforePasswordExpired":false}}';
   my $req = HTTP::Request->new('POST', $okta_authnurl,
      [ 'Accept' => 'application/json', 'Content-Type' => 'application/json' ],
      $json );
   my $res = $ua->request($req);
   die "OKTA AUTHN FAILED: ".$res->status_line."\n".$res->decoded_content."\n"
      unless $res->is_success;
   my ($tok) = $res->decoded_content =~ /"sessionToken"\s*:\s*"([^"]+)"/;
   die "OKTA AUTHN: no sessionToken in response.  Check \$okta_user / \$okta_pass.\n"
      unless $tok;
   return $tok;
}


#OKTA BEGIN


#my $ua = LWP::UserAgent->new;
#my $oktaresponse=$ua->get($oktaspurl);
#open FILEHANDLE, ">bwresponse.html";
#print FILEHANDLE $oktaresponse->{_content};
#close FILEHANDLE;

#OKTA End

my $starttime=time;
print "STARTING LINK CHECKER at ",scalar(localtime($starttime)),"\n";

## configuration constants

my $login='gsa.crawler';
my $password='superuser';

$ENV{CYGWIN}='nodosfilewarning';

our $ASDATABASE = ".linkchecker_as";
our $BWDATABASE = ".linkchecker_bw";
our $CSDATABASE = ".linkchecker_cs";
our $DVDATABASE = ".linkchecker_dv";
our $DATABASE='';
our $DB='';
 
my $VERBOSE = 2;                # 0 = quiet, 1 = noise, 2 = lots of noise
 
my $RECHECK = 0.1 * DAYS;       # seconds between rechecking any URL
my $RECHECK_GOOD = 1 * DAYS;    # seconds between rechecking good URLs
my $REPORT = 0 * DAYS;          # seconds before bad enough to report
 
my $FOLLOW_REDIRECT = 1;        # follow a redirect as if it were a link
my $TIMEOUT = 30;               # timeout on fetch (hard timeout is twice this)
my $MAXSIZE = 1048576;          # max size for fetch (undef if fetch all)
 
my $KIDMAX = 5;                 # how many kids to feed

use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP;

my $transport = Email::Sender::Transport::SMTP->new({
  host => 'mailrelay.bcbsa.com',
  ssl           => 'starttls',             
  port          => 25,                    
  sasl_username => '',
  sasl_password => ''
  #port => 2525,
});

use IO::Socket::SSL qw();
use WWW::Mechanize qw();
my $AGENT = WWW::Mechanize->new(ssl_opts => {
    SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
    verify_hostname => 0,
       # this key is likely going to be removed in future LWP >6.04
});

#my $AGENT = WWW::Mechanize->new();
$AGENT->agent("linkchecker/0.42 " . $AGENT->agent);
$AGENT->env_proxy;
$AGENT->timeout($TIMEOUT);

my $site='http://bluewebportal.bcbs.com';
my $structure_id="2574843";
my $site_gid="2574832";
my $sitename='Blueweb';
my $odbclogn='';
my $odbcpass='';
#my $odbcpass='';
my $dns='DNS';
#my $site='http://bluewebportalpv.bcbsa.com';
if ($ARGV[0] && $ARGV[0]=~/ass?o?c?i?a?t?i?o?n?/i and !$ARGV[1]) {
  print 'this is assoc entered here';
   $site='http://association.bcbs.com';
   $structure_id="2574843";
   $site_gid="846430";
   $sitename='Association';
   $DB=$ASDATABASE;
   $DATABASE=(glob $ASDATABASE)[0];
} elsif ($ARGV[0] && lc($ARGV[1]) eq 'test') {
   $site=$ARGV[0];
   $structure_id="2574843";
   $site_gid="2574832";
   $DB=$CSDATABASE;
   $DATABASE=(glob $CSDATABASE)[0];
} elsif (grep { /dev/i } @ARGV) {
   $site=$ARGV[0];
   $sitename='BluewebDev';
   $structure_id="2574843";
   $site_gid="2574832";
   $DB=$DVDATABASE;
   $DATABASE=(glob $DVDATABASE)[0];
   $odbclogn='liferayrep_dbo';
   $odbcpass='Jk85g9Ms';
   $dns='DNSDV';
   $login='reedfish';
   $password='Today2015#@!';
} else {
   $DB=$BWDATABASE;
   $DATABASE=(glob $BWDATABASE)[0];
}

our $host=($site=~/assoc/)?'association':'blueweb';
#my $host=qr/blueweb.*pv/;

#print "perl ./brsp2.pl ${sitename}_broken_links_text_report.txt $site $site_gid $sitename $structure_id $DB $odbclogn $odbcpass $dns $starttime";
#`perl ./brsp2.pl ${sitename}_broken_links_text_report.txt $site $site_gid $sitename $structure_id $DB $odbclogn $odbcpass $dns $starttime`;
 
my @CHECK = ($site); # list of initial starting points
push @CHECK, 'http://bluewebportal.bcbs.com/sitemap'
      if $sitename eq 'Blueweb';

my %url_to_articleId=();
my %articleId_to_url=();

my $url_to_articleId=();
my $articleId_to_url=();

## ---------------------------------------------------------------------------
## OKTA AUTHENTICATION
## Runs BEFORE the article dump below.  The onetimetoken embedded in
## $oktaspurl is single-use and short-lived, so it must be redeemed
## immediately after the script starts -- not 16 minutes later.
## ---------------------------------------------------------------------------
{
   print "sitename is $sitename\n";
   print "STARTING OKTA AUTH\n";

   ## Get a fresh sessionToken right now.  Doing it here -- rather than
   ## hand-pasting one before launch -- means the token is seconds old when
   ## it is redeemed, instead of expiring during the article dump.
   my $token = $okta_pass ne '' ? okta_session_token() : $okta_manual_token;
   die "No Okta token: set \$okta_pass (preferred) or \$okta_manual_token.\n"
      unless $token;
   $oktaspurl = $okta_ssobase . $token;
   print "OKTA TOKEN OBTAINED (", length($token), " chars)\n";

   $AGENT->get("$oktaspurl");
   die "OKTA GET FAILED: ".$AGENT->res->status_line."\n" unless $AGENT->success;

   ## The Okta SSO endpoint returns an auto-POST SAML form.  That form MUST be
   ## submitted before navigating anywhere else -- navigating away first throws
   ## the form out, the assertion is never delivered, and every subsequent
   ## request comes back unauthenticated (which silently produces an EMPTY
   ## broken-links report instead of an error).
   my @forms = $AGENT->forms;
   unless (@forms) {
      die "OKTA AUTH FAILED: no SAML form in the response.\n"
        . "The onetimetoken in \$oktaspurl is expired or already consumed.\n"
        . "Generate a fresh token (curl to /api/v1/authn), update line 27, and rerun.\n";
   }

   my $response = $AGENT->submit();
   die "OKTA SAML POST FAILED: ".$AGENT->res->status_line."\n" unless $AGENT->success;
   print "RESPONSE=$response<== and STAT=", $AGENT->res->status_line, "\n";

   ## land on the portal using the now-authenticated session
   $AGENT->get("http://bluewebportal.bcbs.com/");
   die "PORTAL GET FAILED: ".$AGENT->res->status_line."\n" unless $AGENT->success;

   my $cookie_count = 0;
   $AGENT->cookie_jar->scan(sub { $cookie_count++ });
   print "COOKIES SET=$cookie_count\n";
   if ($cookie_count == 0) {
      warn "*** WARNING: no cookies after Okta auth -- session probably NOT established ***\n";
   }
   if ($AGENT->content =~ /SAMLRequest|okta\.com\/(login|signin)/i) {
      warn "*** WARNING: portal response still looks like a login page -- check auth ***\n";
   }

   print "OKTA AUTH OK\n";
   print "SITE=$site\n";
}

($articleId_to_url,$url_to_articleId)=
   bcbsa_reports::create_articleid_to_url_hash(
   $site.'/',$site_gid,$sitename,$odbclogn,$odbcpass,$dns,$starttime);
%url_to_articleId=%{$url_to_articleId};
%articleId_to_url=%{$articleId_to_url};

sub PARSE {
   ## return 2 to parse if HTML
   ## return 1 to merely verify existence
   ## return 0 to not even verify existence, but still xref
   ## return -1 to ignore entirely
   my $url = shift;              # URI object (absolute)
   for ($url->scheme) {
      $_||='';
      return 0 unless /^http$/;
   }
   for ($url->equery) {
      $_||='';
      return -1 if /^C=[DMNS];O=[AD]/; # silly mod_index
   }
   for ($url->host) {
      $_||='';
      if (/$host/) {
         for ($url->path) {
            $_||='';
            return 0
               if /update_layout|javascript|images|photos|
                   group\/control_panel|jpg|png|jquery
                  /xm; #  exclude
            return 0 if /^\/(tpc|yapc)\/.*(199[89]|200[012])/; # old
         }
         return 2;                 # default
      }
      return 0 if /$host/;
     
   }
   return 1;                   # ping the world
}

## end configuration constants
 
### internally-defined classes
#
my $email_report = "*** BEGIN REPORT ***\n";
#if (0) {
 
{
   package My::DBI;
   use base 'Class::DBI';

print "DATABASE=$DATABASE\n";

   __PACKAGE__->set_db('Main', "dbi:SQLite:dbname=$DATABASE", undef, undef,
                         {AutoCommit => 1});
 
   sub CONSTRUCT {
     my $class = shift;
     for (qw(My::Page My::Link)) {
       eval { $_->sql_CONSTRUCT->execute };
       die $@ if $@ and $@ !~ /already exists/;
     }
   }
 
   sub atomically {
     my $class = shift;
     my $action = shift;         # coderef
     local $class->db_Main->{AutoCommit}; # turn off AutoCommit for this block
 
     my @result;
     eval {
       @result = wantarray ? $action->() : scalar($action->());
       $class->dbi_commit;
     };
     if ($@) {
       warn "atomically got error: $@";
       my $commit_error = $@;
       eval { $class->dbi_rollback };
       die $commit_error;
     }
     die $@ if $@;
     wantarray ? @result : $result[0];
   }
}

{
   package My::Link;
   our @ISA = qw(My::DBI);

   __PACKAGE__->table('link');
   __PACKAGE__->set_sql(CONSTRUCT => <<'SQL');
CREATE TABLE __TABLE__ (
  src TEXT,
  dst TEXT,
  PRIMARY KEY (src, dst)
)  
SQL
   __PACKAGE__->columns(Primary => qw(src dst));
   __PACKAGE__->has_a(src => 'My::Page');
   __PACKAGE__->has_a(dst => 'My::Page');
}

{
   package My::Page;
   our @ISA = qw(My::DBI);
   use enum qw(:State_ unseen todo working done);

   __PACKAGE__->table('page');
   __PACKAGE__->set_sql(CONSTRUCT => <<"SQL");
CREATE TABLE __TABLE__ (
  location TEXT PRIMARY KEY,
  state INT DEFAULT @{[State_unseen]},
  last_status TEXT,
  last_checked INT,
  last_good INT,
  last_modified INT
)  
SQL
   __PACKAGE__->columns(All => qw(location state last_status
                                 last_checked last_good last_modified));

   __PACKAGE__->has_many(inbound => 'My::Link', 'dst', { order_by => 'src' });
   __PACKAGE__->has_many(outbound => 'My::Link', 'src', { order_by => 'dst' });

   sub make_working_atomically {
      my $self = shift;

      $self->atomically(sub {
                           $self->state == State_todo or return undef;
                           $self->state(State_working);
                           $self->update;
                           return 1;
                        });
   }

   sub create_or_make_todo {
      my $class = shift;
      my $location = shift;

      $class->atomically(sub {
                            my $item = $class->find_or_create(
                               {location => $location});
#print "WHAT IS ITEM $location and STATE=",$item->state,"\n";
                            if ((not defined($item->state)
                                  or $item->state == State_unseen)) {
#print "WHAT IS ITEM $location and STATE=",$item->state,"\n";
                               $item->state(State_todo);
                               $item->update;
                            }
                            $item;
                         });
   }
}

## NOTE: the Okta authentication block that used to live here has been
## moved ABOVE the create_articleid_to_url_hash() call, so that the
## short-lived SAML onetimetoken is used immediately instead of ~16
## minutes later, after the article dump finishes.

### main code begins here

## initialize database if needed
My::DBI->CONSTRUCT;

## reset all working to todo
for my $page (My::Page->search(state => My::Page::State_working)) {
   $page->state(My::Page::State_todo);
   $page->update;
}

my $content_query=<<END;
select
a.userName as publisherName,
replace(replace(aerl.title, '<?xml version=''1.0'' encoding=''UTF-8''?><root available-locales="en_US" default-locale="en_US"><Title language-id="en_US">',''),'</Title></root>','') as contactName,
replace(replace(ae.title, '<?xml version=''1.0'' encoding=''UTF-8''?><root available-locales="en_US" default-locale="en_US"><Title language-id="en_US">',''),'</Title></root>','') as PageName,
a.articleid as PageArticleID,
\'$site/\'+replace(category.name,'_','/')+'/-/asset_publisher/'+replace(substring(typeSettings,CHARINDEX('column-2=com_liferay_asset_publisher_web_portlet_AssetPublisherPortlet_INSTANCE_',typeSettings)+80,12),',','')+'/content/'+urlTitle as BlueWebPage,
a.expirationDate as ExpirationDate,
CASE
  WHEN DATEDIFF(day, a.expirationDate, getdate()) > 0 THEN 'Expired'
  ELSE 'Active'
  END
"Status",
a.content,
r.name,
actionIds
from journalarticle a inner join
(select articleid ,max(modifieddate) modifieddate  from journalarticle
where status ='0'
group by articleId) b
on b.articleid=a.articleId
and a.modifieddate=b.modifieddate
join assetentry ae on  a.resourcePrimKey=ae.classPK
and a.groupId=\'$site_gid\' and ae.groupId=\'$site_gid\'
left join dbo.AssetEntries_AssetCategories entrycat on entrycat.entryId=ae.entryId
left join AssetCategory category on category.categoryId=entrycat.categoryId 
left join Layout layout on layout.groupId=\'$site_gid\' and layout.friendlyurl='/'+REPLACE(category.name,'_','/')
left join assetlink al on al.entryId1=ae.entryId
left join assetEntry aerl on aerl.entryId=al.entryId2
join ResourcePermission rp on rp.primKey=cast(a.resourcePrimKey as varchar) and
rp.name='com.liferay.journal.model.JournalArticle'
and actionIds>0
join Role_ r on rp.roleId=r.roleId
and r.name not like 'LA%'
order by BlueWebPage desc
END

## unless any are todo or finished, prime the pump
unless (() = My::Page->search(state => My::Page::State_todo)
        or () = My::Page->search(state => My::Page::State_done)) {
   print "Starting a new run...\n";
   foreach my $link (@CHECK) {
      print "CHECK LINK=$link<==\n";
      My::Page->create_or_make_todo(URI->new($link)->as_string)
   }
   foreach my $link (keys %url_to_articleId) {
      My::Page->create_or_make_todo(URI->new($link)->as_string)
   }
   my $dbh = DBI->connect("dbi:ODBC:$dns",$odbclogn,$odbcpass);
   my $sth = $dbh->prepare($content_query);
   $sth->{'LongTruncOk'} = 1;
   $sth->{'LongReadLen'} = 20000000;
   $sth->execute();
   ## (removed a stray fetchrow_array here that silently discarded the first row)
   while (my @row=$sth->fetchrow_array) {
      My::Page->create_or_make_todo(URI->new($row[4])->as_string) 
   }
   $sth->finish();
   $dbh->disconnect();
}

## main loop, done by kids:
kids_do(sub {                   # the task
           srand;                # spin random number generator uniquely
           while (my @todo = My::Page->search(state => My::Page::State_todo)) {
              my $page = $todo[rand @todo]; # pick one at random
              unless($page->make_working_atomically) {
                 # someone else got it
                 print "$$ wanted ", $page->location, "\n" if $VERBOSE;
                 next;
              }
              ;
              my $pl=$page->location;
              next if $pl=~/dg\.blueweb/;
              print "$$ doing ", $page->location, "\n" if $VERBOSE > 1;
              do_one_page($page);
           }
        },
        sub {                   # max kids needed
           scalar(() = My::Page->search(state => My::Page::State_todo));
        });
#}
#if (0) {
if (-1<index $site,'bluewebportal') {

   my @row=();my @ids=();
   eval {
      my $dbh = DBI->connect("dbi:ODBC:$dns",$odbclogn,$odbcpass);
      my $sql="select distinct articleId from journalarticle where groupId=\'$site_gid\'";
      #my $sql="select * from journalarticle";
      my $sth = $dbh->prepare($sql);
      $sth->{'LongTruncOk'} = 1;
      $sth->{'LongReadLen'} = 20000000;
      $sth->execute();
      while (@row = $sth->fetchrow_array) {  # retrieve one row
         push @ids, $row[0];
      }
      $sth->finish();
      $dbh->disconnect();
   };
   if ($@) {
      die "DATABASE ERROR=$@\n";
   }
   my $lit = DBI->connect("dbi:SQLite:dbname=$DATABASE", undef, undef); 
   foreach my $row (@ids) {
      print "ROW =>$row<==\n";
      $row=~s/^\///;
      $row="$site/article?id=$row";
      print "TESTING FOR ROW=$row\n";
      my $lth = $lit->prepare("select * from link where src =\'$row\'");
      eval { $lth->execute() }; 
      #$lth->execute();
      my $result = eval { $lth->fetchrow_arrayref->[1] };
      if($result) {
        print "OH HAI. YOU HAVE A RESULT. => $result\n";
      } else { 
        print "0 row(s) returned.\n"
      } #<STDIN>;
   }
   print "DONE WITH IDS\n";
}

#if (0) {
## clean out any unseen at this point (no longer needed)
$_->delete for My::Page->search(state => My::Page::State_unseen);
## display report
print "*** BEGIN REPORT ***\n";
my $reported = 0;
my $done_count = 0;
for my $page (My::Page->search(state => My::Page::State_done,
                               {order_by => 'location'})) {
$done_count++;
print "PAGE=$page<==\n";
   next if $page->last_checked <= ($page->last_good||0) + $REPORT;
   $reported++;
   my $url = URI->new($page->location);
   print "$url:\n";
   $email_report.="$url:\n";
   print "  Status: ", $page->last_status, "\n";
   $email_report.="  Status: ". $page->last_status. "\n"; 
   for (qw(checked good modified)) {
      my $method = "last_$_";
      my $value = $page->$method() or next;
      print "  \u\L$_\E: ".localtime($value)."\n";
      $email_report.="  \u\L$_\E: ".localtime($value)."\n";
   }

   for my $inbound ($page->inbound) {
      my $inbound_page = $inbound->src;
      my $inbound_url = URI->new($inbound_page->location);
      my $rel = $inbound_url->rel($url);
      $rel = $inbound_url->path_query if $rel =~ /^\.\.\/\.\./;
      print "  from $rel\n";
      $email_report.="  from $rel\n";
   }
   for my $outbound ($page->outbound) {
      my $outbound_page = $outbound->dst;
      my $outbound_url = URI->new($outbound_page->location);
      my $rel = $outbound_url->rel($url);
      $rel = $outbound_url->path_query if $rel =~ /^\.\.\/\.\./;
      my $outbound_status = $outbound_page->last_status;
      print "  to $rel: $outbound_status\n";
      $email_report.="  to $rel: $outbound_status\n";
   }
}
print "*** END REPORT ***\n";
print "PAGES CRAWLED=$done_count  PAGES REPORTED=$reported\n";
if ($done_count == 0) {
   warn "*** WARNING: zero pages crawled -- the run did nothing.  Check the Okta auth output above. ***\n";
} elsif ($reported == 0) {
   warn "*** NOTE: $done_count pages crawled, none flagged as broken.  Report is empty by result, not by failure. ***\n";
}
$email_report.="*** END REPORT ***\n";

open (FH,">${sitename}_broken_links_text_report.txt");
print FH $email_report;
close FH;

#}

`perl ./brsp2.pl ${sitename}_broken_links_text_report.txt $site $site_gid $sitename $structure_id $DB $odbclogn $odbcpass $dns $starttime`;

my $finishtime=time;
my $totaltime=$finishtime-$starttime;
my $d="FINISHED CRAWLING LINKS at ",scalar(localtime($finishtime)),"\n";
printf "TOTAL TIME is %d days, %d hours, %d minutes and %d seconds\n",(gmtime $totaltime)[7,2,1,0];

my $email = Email::Simple->create(
   header => [
      To      => '"Lavanya Chimata" <lavanya.chimata@bcbsa.com>',
      From    => '"Lavanya Chimata" <lavanya.chimata@bcbsa.com>',
      Subject => "$sitename Broken Links Report",
   ],
   body => $email_report,
);

sendmail($email, { transport => $transport });

## reset for next pass
for my $page (My::Page->search(state => My::Page::State_done)) {
   $page->state(My::Page::State_unseen);
   $page->update;
}

#exit 0;

### subroutines

sub do_one_page {
   my $page = shift;             # My::Page
   my $url = URI->new($page->location);
   my $parse = PARSE($url);
   if ($parse >= 2) {
      print "Parsing $url\n" if $VERBOSE;
      if (time < ($page->last_checked || 0) + $RECHECK or
            time < ($page->last_good || 0) + $RECHECK_GOOD) {
         print "$url: too early to reparse\n" if $VERBOSE;
         ## reuse existing links
         My::Page->create_or_make_todo($_->dst->location) for $page->outbound;
      } else {
         parse_or_ping($page, $url, "PARSE");
      }
   } elsif ($parse >= 1) {
      print "Pinging $url\n" if $VERBOSE;
      if (time < ($page->last_checked || 0) + $RECHECK or
         time < ($page->last_good || 0) + $RECHECK_GOOD) {
         print "$url: too early to re-ping\n" if $VERBOSE;
         $_->delete for $page->outbound; # delete any existing stale links
      } else {
         parse_or_ping($page, $url, "PING");
      }
   } else {
      print "Skipping $url\n" if $VERBOSE;
      $page->last_status("Skipped");
      $page->last_checked(0);
   }
   $page->state(My::Page::State_done);
   $page->update;
}

sub parse_or_ping {

   my $page = shift;             # My::Page
   my $url = shift;              # URI
   my $kind = shift;             # "PARSE" or "PING"
   

   ## fetch the response
   ## NOTE: $AGENT->get($url) below was previously commented out.  With it
   ## commented out nothing was ever fetched, $AGENT kept returning the stale
   ## start-up response, every page scored as "good", and the report came out
   ## empty every run.
   eval {
      print "url details $url\n";
      $AGENT->get($url);
   };
   if ($@) {
      print "GET ERROR=$@\n";
      print "STATUS=",$AGENT->status,"\n";
   }
   if (-1<index $url,'article?id=') {
      if ($url=~s/^.*article[?]id[=](\d+).*$/$1/) {
         my @row=();
         eval {
            my $dbh = DBI->connect("dbi:ODBC:$dns",$odbclogn,$odbcpass);
            #my $sql = "select articleid,max(article.modifiedDate),max(ae.modifiedDate),\'$site/\'+replace(category.name,'_','/')+'/-/asset_publisher/'+substring(typeSettings,CHARINDEX('column-2=101_INSTANCE_',typeSettings)+22,12)+'/content/'+urlTitle as URL from JournalArticle article join assetentry ae on ae.title=article.title and article.groupId=\'$site_gid\' and ae.groupId=\'$site_gid\'and structureId=\'$structure_id\' and article.articleId=\'$url\' left join dbo.AssetEntries_AssetCategories entrycat on entrycat.entryId=ae.entryId left join AssetCategory category on category.categoryId=entrycat.categoryId join Layout layout on layout.groupId=\'$site_gid\' and layout.friendlyurl='/'+REPLACE(category.name,'_','/') group by articleid, category.name, URL, urlTitle,typeSettings";
            #my $sql = "select articleid,max(article.modifiedDate),max(ae.modifiedDate),'http://bluewebportal.bcbs.com/'+replace(category.name,'_','/')+'/-/asset_publisher/'+substring(typeSettings,CHARINDEX('INSTANCE_',typeSettings)+9,12)+'/content/'+urlTitle as URL from JournalArticle article join assetentry ae on ae.title=article.title and article.groupId=\'$site_gid\' and ae.groupId=\'$site_gid\'and structureId='2574843' and article.articleId=\'$url\' left join dbo.AssetEntries_AssetCategories entrycat on entrycat.entryId=ae.entryId left join AssetCategory category on category.categoryId=entrycat.categoryId join Layout layout on layout.groupId=\'$site_gid\' and layout.friendlyurl='/'+REPLACE(category.name,'_','/') group by articleid, category.name, URL, urlTitle,typeSettings";
            my $sql = "select articleid,max(article.modifiedDate),max(ae.modifiedDate),\'$site/\'+replace(category.name,'_','/')+'/-/asset_publisher/'+replace(substring(typeSettings,CHARINDEX('column-2=com_liferay_asset_publisher_web_portlet_AssetPublisherPortlet_INSTANCE_',typeSettings)+80,12),',','')+'/content/'+urlTitle as URL from JournalArticle article join assetentry ae on ae.classPK=article.resourcePrimKey and article.groupId=\'$site_gid\' and article.status ='0' and ae.groupId=\'$site_gid\'and DDMStructureKey=\'$structure_id\' and article.articleId=\'$url\' left join dbo.AssetEntries_AssetCategories entrycat on entrycat.entryId=ae.entryId left join AssetCategory category on category.categoryId=entrycat.categoryId  join Layout layout on layout.groupId=\'$site_gid\' and layout.friendlyurl='/'+REPLACE(category.name,'_','/') group by articleid, category.name, URL, urlTitle,typeSettings";
            my $sth = $dbh->prepare($sql);
            $sth->{'LongTruncOk'} = 1;
            $sth->{'LongReadLen'} = 20000000;
            $sth->execute();
            @row=$sth->fetchrow_array;
            $sth->finish();
            $dbh->disconnect();
         };
         if ($@) {
            die "DATABASE ERROR=$@\n";
         }
print "\n\n\n\n\nARTICLE ID = $url ==AND== ROW = $row[3]\n\n\n\n\n";
print "\n\n\n\n ROW = $row[1]\n\n\n";
open (TL,">>link_checker.log");
print TL "ARTICLE ID = $url ==AND== ROW = $row[3]\n";
close TL;
         if ($row[3]) {
            $url_to_articleId{$url}=$row[3];
            $articleId_to_url{$row[3]}=$url;
            add_link($page, URI->new($row[3]), $row[3]);
         }
      }
   }

   print "\n\nTEST DETAILS $page";
   #print $AGENT->response->decoded_content();
   ## REMOVED: $AGENT->request->if_modified_since($page->last_modified)
   ## WWW::Mechanize::request() PERFORMS a request, it is not an accessor, and
   ## it dies when called with no argument.  This line was dormant only because
   ## last_modified was never populated (nothing was being fetched).  Skipping
   ## If-Modified-Since is correct here anyway -- a broken-link report wants a
   ## real fetch every pass, not a 304.
   my $content_type=$AGENT->response()->header("Content-Type")||'';
   $content_type=~s/;.*$//;

   ## analyze the results
   if ($AGENT->success && (-1==index $url,'article?id=')) {
      my $now = time;
      $page->last_checked($now);
      $page->last_good($now);
      $page->last_modified($AGENT->response()->header("Last_Modified") ||
         $AGENT->response()->header("Date"));
      $_->delete for $page->outbound; # delete any existing stale links

      if ($content_type eq "text/html") {
         if ($kind eq "PARSE") {
            print "$url: parsed\n" if $VERBOSE;
if (-1<index $url,'leaf') {
   print "\n\n\n   WE HAVE LEAF => $url\n\n\n\n";
   open (FH,">leaf_pages/leaf_$$.txt");
   print FH $url;
   close FH;
}
            $page->last_status("Verified and parsed");
            my %seen=();
            foreach my $link ($AGENT->links()) {
               my $print_link=$link->url();
               $print_link=~s/[^[:ascii:]]+//g;
               next if $print_link=~/javascript|update_layout/;
               $seen{$link->url()}++ or add_link($page, $link);
            }
         } else {                  # presume $kind = PING
            print "$url: good ping\n" if $VERBOSE;
            $page->last_status("Verified (contents not examined)");
         }
      } else {
         #print "$url: content = ",$AGENT->content,"\n" if $VERBOSE;
         $page->last_status("Verified (content = ".$AGENT->content.")");
      }
   } elsif ($AGENT->status == 304) { # not modified
      print "$url: not modified\n" if $VERBOSE;
      my $now = time;
      $page->last_checked($now);
      $page->last_good($now);
      ## reuse existing links
      My::Page->create_or_make_todo($_->dst->location) for $page->outbound;
   } elsif ($AGENT->res->is_redirect) {
      my $location = $AGENT->response()->header("Location")||'';
      print "$url: redirect to $location\n" if $VERBOSE;
      $_->delete for $page->outbound; # delete any existing stale links
      add_link($page, $location) if $FOLLOW_REDIRECT;
      $page->last_status("Redirect (status = ".$AGENT->status.")
         to $location");
      $page->last_checked(time);
   } else {
      print "$url: not verified: ", $AGENT->status, "\n" if $VERBOSE;
      $_->delete for $page->outbound; # delete any existing stale links
      $page->last_status("NOT Verified (status = ".($AGENT->status).")");
      $page->last_checked(time);
   }
   $page->update; 

}

sub add_link {
   my $page = shift;             # My::Page
   my $link = shift;
   my $tiny = shift || '';
   return unless $link;
   my $url='';
   if (ref $link eq 'WWW::Mechanize::Link') {
      $url=$link->url_abs();
   } elsif (ref $link eq 'URI::http') {
      $url=Data::Dump::Streamer::Dump($link)->Out();
      $url=~s/^.*?['](.*?)['].*$/$1/s;
   } else {
      $url=$link;
   }
   $url= URI->new($url);
   return if PARSE($url) < 0;    # skip any links to non-xref pages
   #print "saw $url\n" if $VERBOSE > 1;
   if ($tiny) {
print "\n\n\n\n   ADDING TINY! => $tiny   \n\n\n\n";
open (TL,">>link_checker.log");
print TL "\n\n\n\n   ADDING TINY! => $tiny   \n\n\n\n";
close TL;
   }

   my $newpage = My::Page->create_or_make_todo($url);
   ## the following might die if there's already one link there
   eval { My::Link->create({src => $page, dst => $newpage}) };
   die $@ if $@ and not $@ =~ /UNIQUE constraint/;
}

sub kids_do {
   my $code_task = shift;
   my $code_count = shift;

   use POSIX qw(WNOHANG);

   my %kids;

   while (keys %kids or $code_count->()) {
      ## reap kids
      while ((my $kid = waitpid(-1, WNOHANG)) > 0) {
         ## warn "$kid reaped";    # trace
         delete $kids{$kid};
      }
      ## verify live kids
      for my $kid (keys %kids) {
         next if kill 0, $kid;
         warn "*** $kid found missing ***"; # shouldn't happen
         delete $kids{$kid};
      }
      ## launch kids
      if (keys %kids < $KIDMAX
            and keys %kids < $code_count->()) {
         ## warn "forking a kid";  # trace
         my $kid = fork;
         if (defined $kid) {       # good parent or child
            if ($kid) {             # parent
               $kids{$kid} = 1;
            } else {
               $code_task->();       # the real task
               exit 0;
            }
         } else {
            warn "cannot fork: $!"; # hopefully temporary
            sleep 1;
            next;                   # outer loop
         }
      }
      print "[", scalar keys %kids, " kids]\n" if $VERBOSE;
      sleep 1;
   }
}

