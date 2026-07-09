<%@include file="../init.jsp"%>


<h4>
	Legal Name <a href="#" class="tooltip"></a>
</h4>
	${brandrequest.legalName}
<br />
<h4>
	Trade Name
</h4>			
<c:forEach items="${brandrequest.tradeNames}" var="tradename">
				<c:out value="${tradename}" />
				<br />			
</c:forEach>
<br />

<h4>
	Type of Service Request
</h4>
	${brandrequest.cobrandReviewType.cobrandRevwTypNm}	
 <h4>
	BCBSA Support
</h4>
<c:if test="${brandrequest.cobrandReviewType.cobrandRevwTypNm == 'Select'}">
<c:forEach items="${brandrequest.selectedBcbaSupport}" var="bcbasupport">
				<c:out value="${bcbasupport.coBrandBcbsaSupportDesc}" />
				<br />			
</c:forEach>
</c:if>
	
<%-- <h4>
	Co-Branding Renewal
</h4>
     <c:if test="${brandrequest.cobrandRenewalType.cobrandRenwTypNm == 'Select' 
     || brandrequest.cobrandRenewalType.cobrandRenwTypNm == 'Premier'
     || brandrequest.cobrandRenewalType.cobrandRenwTypNm == 'Strategic'}">
	 ${brandrequest.cobrandRenewalType.cobrandRenwTypNm}- Renewal
	 </c:if>  --%>
	
<c:if test="${brandrequest.cobrandRenewalType.cobrandRenwTypNm== 'Strategic'}">
<h4>
	Strategic Renewal Rational Description
</h4>
    ${brandrequest.cbStrategicRenewRational}	
</c:if>	

<c:if test="${not empty brandrequest.requestedResponseDate}">	
	<br />
	<h4>
		Expedited, Requested Response Date
	</h4>
		${brandrequest.requestedResponseDate}	
</c:if>	

<hr />
<h4>
	Chosen Co-Branding Service Categories
</h4>
	<c:forEach var="serviceCategory" items="${brandrequest.brandRqstServiceCategories}">
		<c:out value="${serviceCategory.srvcCtgyNm}" />	<c:if test="${serviceCategory.srvcCtgyNm == 'Other'}"> - ${brandrequest.othSrvcCtgyNm}</c:if>
		<br />			
	</c:forEach>			
<hr />

<%-- ===== Co-Branding Partner Form 17-question display block start ===== --%>

<%-- Q1-Q9 Brand Questions: shown only for NEW records --%>
<c:if test="${not empty brandrequest.cbQ1LegalNameCnfrmd}">
	<h4>Have you confirmed the legal name of this entity?</h4>
	${brandrequest.cbQ1LegalNameCnfrmd == 'Y' ? 'Yes' : 'No'}
	<br /><hr />

	<h4>Will this solution result in the Brands appearing on a debit card or reward card?</h4>
	${brandrequest.cbQ2DebitCardInd == 'Y' ? 'Yes' : 'No'}
	<c:if test="${brandrequest.cbQ2DebitCardInd == 'Y' and not empty brandrequest.cbQ2LicenseAgmtDt}">
		<br />Date BCBSA confirmed the license agreement / application sent: ${brandrequest.cbQ2LicenseAgmtDt}
	</c:if>
	<br /><hr />

	<h4>Will this solution result in the Brands appearing in a client list or testimonial?</h4>
	${brandrequest.cbQ3ClientListInd == 'Y' ? 'Yes' : 'No'}
	<c:if test="${brandrequest.cbQ3ClientListInd == 'Y' and brandrequest.cbQ3ExceptionAckInd == 'Y'}">
		<br /><em>Plan acknowledged exception review.</em>
	</c:if>
	<br /><hr />

	<h4>During your review, did you locate any possible misuse of the Brands?</h4>
	${brandrequest.cbQ4BrandMisuseInd == 'Y' ? 'Yes' : 'No'}
	<c:if test="${brandrequest.cbQ4BrandMisuseInd == 'Y'}">
		<br /><strong>Links to misuse:</strong><br />${brandrequest.cbQ4MisuseLinksTxt}
		<br /><strong>Contact name and email:</strong><br />${brandrequest.cbQ4MisuseContactTxt}
		<c:if test="${brandrequest.cbQ4MisuseAckInd == 'Y'}">
			<br /><em>Plan acknowledged BCBSA review.</em>
		</c:if>
	</c:if>
	<br /><hr />

	<h4>Does the company's name, logo or slogan include elements likely to infringe on the Brands?</h4>
	${brandrequest.cbQ5NameLogoInfrngInd == 'Y' ? 'Yes' : 'No'}
	<c:if test="${brandrequest.cbQ5NameLogoInfrngInd == 'Y'}">
		<br /><strong>Link showing name/logo/slogan:</strong><br />${brandrequest.cbQ5InfrngLinksTxt}
		<br /><strong>Contact name and email:</strong><br />${brandrequest.cbQ5InfrngContactTxt}
		<c:if test="${brandrequest.cbQ5InfrngAckInd == 'Y'}">
			<br /><em>Plan acknowledged BCBSA review.</em>
		</c:if>
	</c:if>
	<br /><hr />

	<h4>To the best of your knowledge, is the company financially stable?</h4>
	${brandrequest.cbQ6FinlStableInd == 'Y' ? 'Yes' : 'No'}
	<br /><hr />

	<h4>Has the company been convicted of a felony within the past three years?</h4>
	${brandrequest.cbQ7FelonyInd == 'Y' ? 'Yes' : 'No'}
	<br /><hr />

	<h4>Have you confirmed the company is not on a disapproved or competitor list?</h4>
	<c:choose>
		<c:when test="${brandrequest.cbQ8NotOnListInd == 'Y'}">Yes &mdash; company does not appear on any applicable lists</c:when>
		<c:when test="${brandrequest.cbQ8NotOnListInd == 'E'}">Yes &mdash; appears on lists but solely PBM services or exception documented with BCBSA</c:when>
		<c:when test="${brandrequest.cbQ8NotOnListInd == 'N'}">No</c:when>
	</c:choose>
	<br /><hr />

	<h4>Does the company have a reputation that would dilute or tarnish the Brands?</h4>
	${brandrequest.cbQ9ReputationInd == 'Y' ? 'Yes' : 'No'}
	<br /><hr />
</c:if>

<%-- Q10-Q17 IPP Questions --%>
<c:if test="${brandrequest.serviceCatQuestionsFlag == 'Y'}">
	<c:if test="${not empty brandrequest.cbQ10InterPlanExecTxt}">
		<h4>Inter-Plan Executive / Plan IPP team contact</h4>
		${brandrequest.cbQ10InterPlanExecTxt}
		<br /><hr />
	</c:if>

	<h4>Do these services generate a claim against the member's Blue benefits or is this a carveout?</h4>
	<c:choose>
		<c:when test="${brandrequest.serviceCategoryBlueBenefit == 'CARVEOUT'}">Carveout</c:when>
		<c:when test="${brandrequest.serviceCategoryBlueBenefit == 'CLAIM'}">Generates a claim against the member's Blue benefits</c:when>
		<c:when test="${brandrequest.serviceCategoryBlueBenefit == 'OTHER'}">Other - ${brandrequest.cbQ11OtherTxt}</c:when>
		<c:otherwise>${brandrequest.serviceCategoryBlueBenefit}</c:otherwise>
	</c:choose>
	<br /><hr />

	<c:if test="${not empty brandrequest.cbQ12TelehealthSvcInd}">
		<h4>Is this a clinical telehealth service or solution?</h4>
		${brandrequest.cbQ12TelehealthSvcInd == 'Y' ? 'Yes' : 'No'}
		<br /><hr />
	</c:if>
	<c:if test="${not empty brandrequest.cbQ13VirtualOnlyInd}">
		<h4>Are the telehealth services virtual only?</h4>
		${brandrequest.cbQ13VirtualOnlyInd == 'Y' ? 'Yes' : 'No'}
		<br /><hr />
	</c:if>

	<c:if test="${not empty brandrequest.serviceCategoryNationalAccountMember}">
		<h4>Is this program/service available to your national account members that reside outside of your Plan's service area?</h4>
		<c:choose>
			<c:when test="${brandrequest.serviceCategoryNationalAccountMember == 'Y'}">Yes</c:when>
			<c:when test="${brandrequest.serviceCategoryNationalAccountMember == 'N'}">No</c:when>
			<c:otherwise>${brandrequest.serviceCategoryNationalAccountMember}</c:otherwise>
		</c:choose>
		<br /><hr />
	</c:if>

	<c:if test="${not empty brandrequest.serviceCategoryServiceEntail}">
		<h4>What do the services entail?</h4>
		${brandrequest.serviceCategoryServiceEntail}
		<br /><hr />
	</c:if>

	<c:if test="${not empty brandrequest.cbQ16ProviderOutreachInd}">
		<h4>Does this solution include outreach to providers outside of your service area?</h4>
		${brandrequest.cbQ16ProviderOutreachInd == 'Y' ? 'Yes' : 'No'}
		<br /><hr />
	</c:if>
	<c:if test="${brandrequest.cbQ16ProviderOutreachInd == 'Y' and not empty brandrequest.cbQ17ProviderOutreachTxt}">
		<h4>What does the provider outreach entail?</h4>
		${brandrequest.cbQ17ProviderOutreachTxt}
		<br /><hr />
	</c:if>
</c:if>

<%-- ===== Co-Branding Partner Form 17-question display block end ===== --%>

<%-- Legacy Cobranding Criteria - shown only when legacy data present --%>
<c:if test="${empty brandrequest.cbQ1LegalNameCnfrmd and (brandrequest.demoFinancial == 'Y' or brandrequest.noFelonyRecord == 'Y' or brandrequest.reputationBrand == 'Y' or brandrequest.prohibitatedCompany == 'Y' or brandrequest.noMisuseOfBrands == 'Y')}">
<!-- Cobranding Criteria Requirement customisation start -->

<h4>

	Demonstrate Financial Stability

</h4>

<c:if test="${brandrequest.demoFinancial =='Y'}">

Yes

</c:if>

<br />

<hr />

<h4>

	No Felony Record

</h4>

<c:if test="${brandrequest.noFelonyRecord =='Y'}">

Yes

</c:if>

<br />

<hr />

<h4>

	Reputation Brand

</h4>

<c:if test="${brandrequest.reputationBrand =='Y'}">

Yes

</c:if>

<br />

<hr />

<h4>

	Prohibited Company

</h4>

<c:if test="${brandrequest.prohibitatedCompany =='Y'}">

Yes

</c:if>

<br />

<hr />

<h4>

	No Misuse of Brands

</h4>

<c:if test="${brandrequest.noMisuseOfBrands =='Y'}">

Yes

</c:if>

<br />

<hr />



<!-- Cobranding Criteria Requirement customisation end -->
</c:if>
<h4>
	State of Incorporation
</h4>
	${brandrequest.stateOfIncorporation.usStateNm}
<br />
<hr />
<h4>Address</h4>
	${brandrequest.address1}
<br />
	<c:if test="${not empty brandrequest.address2}">
	    <c:out value="${brandrequest.address2}" />
		<br />
	</c:if>			
	${brandrequest.city}
<br />
	${brandrequest.state.usStateNm}, ${brandrequest.zipCode}
<br />
	${brandrequest.phone}
<br />
<br />
<hr />
<h4>
	D&amp;B Number (If Known)
</h4>
<c:choose>
	<c:when test="${brandrequest.dandbNumber != ''}">
    				<c:out value="${brandrequest.dandbNumber}" />
	</c:when>
	<c:otherwise>
      		None Entered
	</c:otherwise>
</c:choose>			
<br />
<h4>
	Company Website
</h4>
	${brandrequest.companyWebSite}
<br />
<h4>
	Unlicensed Affiliate?
</h4>			
	<c:choose>
		<c:when test="${brandrequest.isUnlicensed == 'Yes'}">
	    			Yes<br/>Name: <c:out value="${brandrequest.plan.planNm}" />
		</c:when>
		<c:otherwise>
	      	No
		</c:otherwise>
	</c:choose>	
<br />			
<h4>
	Co-Branding Business Type
</h4>
	${brandrequest.businessType.busTypDesc}
<br />			
<h4>
	Is the company a Third Party Administrator (TPA)?
</h4>
	<c:choose>
		<c:when test="${brandrequest.isTpa =='Yes'}">
	    			Yes        		
		</c:when>
		<c:otherwise>
	      	No
		</c:otherwise>
	</c:choose>
<%-- Group Account Type: show only for legacy records (created before the 17-question
     enhancement). New records are identified by CB_Q1_LEGAL_NAME_CNFRMD being populated;
     for those, Group Account Type is neither captured nor displayed. --%>
<c:if test="${empty brandrequest.cbQ1LegalNameCnfrmd and not empty brandrequest.groupAccountType.grpAcctTypDesc}">
<h4>
	Choose Group Account Type
</h4>
	${brandrequest.groupAccountType.grpAcctTypDesc}
<br /><hr />
</c:if>
<h4>
	Describe where and how co-branding will appear.
</h4>
<div class="cobrandDescription">${brandrequest.coBrandDescription}</div>
<br />

<c:if test="${brandrequest.cobrandReviewType.cobrandRevwTypNm == 'Strategic'}">
<h4>
	Please provide the decision factors in which your Plan concluded this partner qualifies at the Identified Level.
</h4>
${brandrequest.cbStrategicDecisionFact}
</c:if>
<br /> 

<div id="attachments">
	<h4>Attachments</h4>
	<hr />
	<c:choose>
		<c:when test="${fn:length(brandrequest.attachmentList) gt 0}">
			<table class="table table-striped table-bordered">
				<tr>
					<th>File Name</th>
					<th>Description</th>
				</tr>
				<c:forEach var="attachment" items="${brandrequest.attachmentList}" varStatus="status">
					<tr>
						<% if( (!"MyPendingWorkflowTaskWeb".equalsIgnoreCase(themeDisplay.getPortletDisplay().getId())) ) {%>
						<td> 
							<portlet:resourceURL var="dUrl" id="AttachmentDownload">
								<portlet:param name="fileId" value="${attachment.fileId}"/>
							</portlet:resourceURL>
							<a href="${dUrl}" target="_blank">${attachment.fileName}</a>  
						</td>
						<% } else { %>	
						<td><c:out value="${attachment.fileName}" /></td>
						<% } %>					
						<td class="cobrandDescription"><c:out value="${attachment.fileDescription}" /></td>
					</tr>
				</c:forEach>
			</table>
		</c:when>
		<c:otherwise>
			No Attachments
		</c:otherwise>
	</c:choose>
</div>

