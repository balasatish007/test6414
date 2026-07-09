package com.bcbsa.brp.model.util;

import com.bcbsa.brp.constants.BRPConstants;
import com.bcbsa.brp.model.BrandRequest;
import com.bcbsa.brp.model.BrandRequestBcbsaSupport;
import com.bcbsa.brp.model.BrandRequestServiceCategory;
import com.bcbsa.brp.model.BrandRequestServiceCategoryPK;
import com.bcbsa.brp.model.BusinessType;
import com.bcbsa.brp.model.CoBrandBcbsaSupport;
import com.bcbsa.brp.model.CobrandReviewType;
import com.bcbsa.brp.model.GroupAccountType;
import com.bcbsa.brp.model.LegalEntity;
import com.bcbsa.brp.model.LegalEntityAssociation;
import com.bcbsa.brp.model.LegalEntityAssociationPK;
import com.bcbsa.brp.model.LegalEntityRelationship;
import com.bcbsa.brp.model.LegalEntityTradeName;
import com.bcbsa.brp.model.LegalEntityTradeNamePK;
import com.bcbsa.brp.model.Plan;
import com.bcbsa.brp.model.RequestCategory;
import com.bcbsa.brp.model.ServiceCategory;
import com.bcbsa.brp.model.UsState;
import com.bcbsa.brp.model.UserUploadCobrandSample;
import com.bcbsa.brp.model.UserUploadCobrandSamplePK;
import com.bcbsa.brp.model.UserUploadFile;
import com.bcbsa.brp.model.UserUploadFilePK;
import com.bcbsa.brp.sanatize.InputSanitizer;
import com.bcbsa.brp.service.BusinessTypeService;
import com.bcbsa.brp.service.CoBrandBCBSASupportService;
import com.bcbsa.brp.service.CobrandReviewTypeService;
import com.bcbsa.brp.service.GroupAccountTypeService;
import com.bcbsa.brp.service.LegalEntityAssociationService;
import com.bcbsa.brp.service.LegalEntityRelationshipService;
import com.bcbsa.brp.service.LegalEntityService;
import com.bcbsa.brp.service.PlanService;
import com.bcbsa.brp.service.RequestCategoryService;
import com.bcbsa.brp.service.ServiceCategoryService;
import com.bcbsa.brp.service.UsStateService;
import com.bcbsa.brp.service.UserUploadCobrandSampleService;
import com.bcbsa.brp.service.UserUploadFileService;
import com.bcbsa.brp.service.exception.ServiceException;
import com.bcbsa.brp.vo.BrandRequestVo;
import com.bcbsa.brp.vo.BusinessTypeVo;
import com.bcbsa.brp.vo.CoBrandBcbsaSupportVO;
import com.bcbsa.brp.vo.CobrandRenewalType;
import com.bcbsa.brp.vo.CobrandReviewTypeVo;
import com.bcbsa.brp.vo.FileAttachmentVo;
import com.bcbsa.brp.vo.GeneralBrandInquiryVo;
import com.bcbsa.brp.vo.GeneralBrandRequestVo;
import com.bcbsa.brp.vo.GroupAccountTypeVo;
import com.bcbsa.brp.vo.NonCoBrandRequestVo;
import com.bcbsa.brp.vo.PlanVo;
import com.bcbsa.brp.vo.RequestCategoryVo;
import com.bcbsa.brp.vo.ServiceCategoryVo;
import com.bcbsa.brp.vo.UsStateVo;
import com.bcbsa.brp.vo.UserDetailsVo;
import com.liferay.document.library.kernel.model.DLFileEntry;
import com.liferay.portal.kernel.log.Log;
import com.liferay.portal.kernel.log.LogFactoryUtil;
import com.liferay.portal.kernel.model.User;
import com.liferay.portal.kernel.service.UserLocalServiceUtil;
import com.liferay.portal.kernel.util.PortalUtil;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * This class is responsible for mapping between various incarnations of
 * BrandRequest:
 * <ul>
 * <li>BrandRequestFormModel -> BrandRequest</li>
 * <li>BrandRequest -> BrandRequestFormModel</li>
 * </ul>
 * 
 * Having this class separate from the Controller logic separates those concerns
 * and results in cleaner code.
 * 
 * This class is not a Spring bean so we have more control over its Lifecycle.
 * This allows us to perform one-off performance optimizations that, for
 * example, might align with the life of the current Session (without cluttering
 * up this class with a Session reference).
 * 
 * @author Steve Perry
 * 
 */
@Service
public class BrandRequestVoMapper {
	private static final Log log = LogFactoryUtil.getLog(BrandRequestVoMapper.class);

	@Autowired
	private BusinessTypeService businessTypeService;

	@Autowired
	private CobrandReviewTypeService cobrandReviewTypeService;

	@Autowired
	private GroupAccountTypeService groupAccountTypeService;

	@Autowired
	private ServiceCategoryService serviceCategoryService;

	@Autowired
	private UsStateService usStateService;

	@Autowired
	private LegalEntityService legalEntityService;

	@Autowired
	private LegalEntityRelationshipService legalEntityRelationshipService;

	@Autowired
	private PlanService planService;

	@Autowired
	private UserUploadFileService userUploadFileService;
	
	
	@Autowired
	private UserUploadCobrandSampleService userUploadCobrandSampleService;
	
	

	@Autowired
	private RequestCategoryService requestCategoryService;

	@Autowired
	private LegalEntityAssociationService legalEntityAssociationService;
	
	@Autowired
	private CoBrandBCBSASupportService coBrandBCBSASupportService;

	// Private state
	private List<BusinessType> businessTypes;
	private List<CobrandReviewType> cobrandReviewTypes;
	private List<CobrandRenewalType> cobrandRenewalTypes;
	private List<GroupAccountType> groupAccountTypes;
	private List<ServiceCategory> serviceCategories;
	private List<UsState> usStates;
	private List<Plan> plans;


	private Map<String,String> cobrandReviewTypesMap;
	private Map<String,String> cobrandRenewalTypesMap;
	// private List<RequestCategory> requestCategories;

	/**
	 * Do not create an instance of this class directly.
	 * 
	 * Use the VoMapperFactory to do this.
	 * 
	 * @throws ServiceException
	 */
	protected BrandRequestVoMapper() throws ServiceException {
		// Nothing to do
	}

	/**
	 * Maps the specified Brand Request Value Object (probably from the UI) to a
	 * BrandRequest domain object (probably to be persisted to the DB).
	 * 
	 * @param vo
	 * @return
	 * @throws ServiceException
	 */
	public BrandRequest fromValueObject(BrandRequestVo vo) throws ServiceException {

		BrandRequest ret = new BrandRequest();

		Date now = new Date();
		
		try {
		// Legal Entity
		LegalEntity legalEntity = legalEntityService.fetchByName(santizeInput(vo.getLegalName()));
		if (legalEntity == null) {
			// There is no legal entity by that name. So create it
			legalEntity = new LegalEntity();
			//System.out.println("InputSanitizer.sanitize(legalName): "+santizeInput(vo.getLegalName()));
			legalEntity.setLegalNm(santizeInput(vo.getLegalName()));
		}
		// String planCode = vo.getPlanCode();
		byte b = 0;
		byte isUnlicensed = new Byte(b);
		if (vo.getIsUnlicensed().equals(BRPConstants.YES_FLAG)) {
			b = 1;
			isUnlicensed = new Byte(b);
			String planCode = santizeInput(vo.getPlan().getPlanCd());
			String relationshipCode = BRPConstants.AFFILIATE_RELATIONSHIP_CODE;

			if (planCode != null && !planCode.isEmpty()) {
				// Get the associated Legal Entity by plan code
				LegalEntity associatedLegalEntity = legalEntityService.getLegalEntityByPlanCode(planCode);
				LegalEntityAssociation legalEntityAssociation = new LegalEntityAssociation();
				ret.setAssocLegalEntity(associatedLegalEntity);
				// Get LegalEntityRelationship object
				LegalEntityRelationship relationship = legalEntityRelationshipService.getLegalEntityRelationshipByCode(relationshipCode);
				legalEntityAssociation.setUnlcnsdAffltInd(isUnlicensed);
				legalEntityAssociation.setCreatedBy(santizeInput(vo.getPortalUser()));
				legalEntityAssociation.setCreateTs(now);
				legalEntityAssociation.setUpdatedBy(santizeInput(vo.getPortalUser()));
				legalEntityAssociation.setUpdateTs(now);
				// TODO: Where do we get inactvDt date?
				// legalEntityAssociation.setInactvDt(now);
				legalEntityAssociation.setLegalEntity(legalEntity);
				legalEntityAssociation.setAssociatedLegalEntity(associatedLegalEntity);
				legalEntityAssociation.setLegalEntityRelationship(relationship);
				LegalEntityAssociationPK pk = new LegalEntityAssociationPK();
				pk.setLegalEntityUid(legalEntity.getLegalEntityUid());
				pk.setAsctdLegalEntityUid(associatedLegalEntity.getLegalEntityUid());
				pk.setLegalEntityRelshpCd(relationship.getLegalEntityRelshpCd());
				legalEntityAssociation.setId(pk);
				//ret.setPartnerLegalEntity(associatedLegalEntity);
				ret.setLegalEntityRelationship(relationship);
				List<LegalEntityAssociation> leAssociationList = legalEntityAssociationService.getLegalEntityAssociationsById(pk);
				log.info("Le Association List Size: " + leAssociationList + "---" + ( leAssociationList != null ? leAssociationList.size() : "NULL"));
				if(null != leAssociationList && leAssociationList.size() > 0){
					ret.setLegalEntityAssociation(null);
				} else {
					ret.setLegalEntityAssociation(legalEntityAssociation);
				}

			}
		}

		// Trade Names
		String[] tradeNames = vo.getTradeNames();
		LinkedHashSet<LegalEntityTradeName> tradeNameSet = new LinkedHashSet<LegalEntityTradeName>();
		if (tradeNames != null && tradeNames.length > 0) {
			for (String str : tradeNames) {
				if (StringUtils.isNotEmpty(str)) {
					str = santizeInput(str);
					LegalEntityTradeName tradeName = new LegalEntityTradeName();
					tradeName.setLegalEntity(legalEntity);
					tradeName.setCreatedBy(santizeInput(vo.getPortalUser()));
					tradeName.setCreateTs(now);
					tradeName.setUpdatedBy(santizeInput(vo.getPortalUser()));
					tradeName.setUpdateTs(now);
					LegalEntityTradeNamePK pk = new LegalEntityTradeNamePK(legalEntity.getLegalEntityUid(), str);
					tradeName.setId(pk);
					tradeNameSet.add(tradeName);
				}
			}
		}
		legalEntity.setLegalEntityTradeNames(tradeNameSet);

		//co  brand renwe message
		if(vo.getCbStrategicRenewRational()!=null)
			ret.setCbStrategicRenewRational(santizeInput(vo.getCbStrategicRenewRational()));

		if(vo.getCbStrategicDecisionFact()!=null)
			ret.setCbStrategicDecisionFact(santizeInput(vo.getCbStrategicDecisionFact()));

		// Cobrand Review Type (a.k.a., Service
		ret.setCobrandReviewType(getSelectedCobrandReviewType(vo.getCobrandReviewType().getCobrandRevwTypUid()));
		
		//commented to remove renewal type drop-down(KP)
		//if(vo.getCobrandRenewalType().getCobrandRenwTypUid()!=null)
		//ret.setCobrandRenewalType(getSelectedCobrandReviewType(Long.parseLong(vo.getCobrandRenewalType().getCobrandRenwTypUid())));

		// Service Categories - there is a M2M relationship between BrandRequest
		/// and ServiceCategory. So we need to create and set the appropriate
		// objects
		/// in the model.
		// int[] serviceCategories = vo.getServiceCategories();
		String[] serviceCategoriesArray = null;
		List<ServiceCategoryVo> serviceCategories = vo.getBrandRqstServiceCategories();
		if (serviceCategories != null && !serviceCategories.isEmpty()) {
			serviceCategoriesArray = new String[serviceCategories.size()];
			int count = 0;
			for (ServiceCategoryVo svo : serviceCategories) {
				String srvcCtgyUid = svo.getSrvcCtgyUid();
				if (StringUtils.isEmpty(srvcCtgyUid)) {
					continue;
				}
				serviceCategoriesArray[count++] = svo.getSrvcCtgyUid();
			}
		}

		List<ServiceCategory> selectedServiceCategories = getSelectedServiceCategories(serviceCategoriesArray);
		Set<BrandRequestServiceCategory> brandRequestServiceCategorySet = new HashSet<>();
		for (ServiceCategory sc : selectedServiceCategories) {
			BrandRequestServiceCategory brsc = new BrandRequestServiceCategory();
			brsc.setCreateTs(now);
			brsc.setCreatedBy(santizeInput(vo.getPortalUser()));
			brsc.setUpdateTs(now);
			brsc.setUpdatedBy(santizeInput(vo.getPortalUser()));
			if (sc.getSrvcCtgyNm().equals(BRPConstants.OTHER)) {
				brsc.setOthSrvcCtgyNm(vo.getOthSrvcCtgyNm());
			}
			brsc.setBrandRequest(ret);
			brsc.setServiceCategory(sc);
			BrandRequestServiceCategoryPK pk = new BrandRequestServiceCategoryPK(ret.getBrandRqstUid(), sc.getSrvcCtgyUid());
			brsc.setId(pk);
			brandRequestServiceCategorySet.add(brsc);
		}
		ret.setBrandRequestServiceCategories(brandRequestServiceCategorySet);
		
		//Co-Branding Partner Form 17-question enhancement start
		//Clear any orphaned child values before mapping (e.g. Q2 date left over
		//when the final answer is No) so the persisted record is consistent.
		sanitizeConditionalAnswers(vo);
		//Q1-Q9 Brand Questions - always saved (always shown on form)
		ret.setCbQ1LegalNameCnfrmd(vo.getCbQ1LegalNameCnfrmd());
		ret.setCbQ2DebitCardInd(vo.getCbQ2DebitCardInd());
		ret.setCbQ2LicenseAgmtDt(vo.getCbQ2LicenseAgmtDt());
		ret.setCbQ3ClientListInd(vo.getCbQ3ClientListInd());
		ret.setCbQ3ExceptionAckInd(vo.getCbQ3ExceptionAckInd());
		ret.setCbQ4BrandMisuseInd(vo.getCbQ4BrandMisuseInd());
		ret.setCbQ4MisuseLinksTxt(vo.getCbQ4MisuseLinksTxt());
		ret.setCbQ4MisuseContactTxt(vo.getCbQ4MisuseContactTxt());
		ret.setCbQ4MisuseAckInd(vo.getCbQ4MisuseAckInd());
		ret.setCbQ5NameLogoInfrngInd(vo.getCbQ5NameLogoInfrngInd());
		ret.setCbQ5InfrngLinksTxt(vo.getCbQ5InfrngLinksTxt());
		ret.setCbQ5InfrngContactTxt(vo.getCbQ5InfrngContactTxt());
		ret.setCbQ5InfrngAckInd(vo.getCbQ5InfrngAckInd());
		ret.setCbQ6FinlStableInd(vo.getCbQ6FinlStableInd());
		ret.setCbQ7FelonyInd(vo.getCbQ7FelonyInd());
		ret.setCbQ8NotOnListInd(vo.getCbQ8NotOnListInd());
		ret.setCbQ9ReputationInd(vo.getCbQ9ReputationInd());

		//Q10-Q17 IPP Questions - saved only when service-category triggered
		String serviceCatQueFlag = vo.getServiceCatQuestionsFlag();
		if (serviceCatQueFlag != null && serviceCatQueFlag.equalsIgnoreCase("Y")) {
			ret.setCbQ10InterPlanExecTxt(vo.getCbQ10InterPlanExecTxt());
			// Q11 radio value (CARVEOUT / CLAIM / OTHER) reuses SRVC_BLUE_BENEFITS column
			ret.setServiceCategoryBlueBenefit(vo.getServiceCategoryBlueBenefit());
			ret.setCbQ11OtherTxt(vo.getCbQ11OtherTxt());
			ret.setCbQ12TelehealthSvcInd(vo.getCbQ12TelehealthSvcInd());
			ret.setCbQ13VirtualOnlyInd(vo.getCbQ13VirtualOnlyInd());
			// Q14 reuses SRVC_NATIONAL_ACCOUNT_MEMBERS column (now Y/N)
			ret.setServiceCategoryNationalAccountMember(vo.getServiceCategoryNationalAccountMember());
			// Q15 reuses SRVC_SERVICES_ENTAIL column (free text)
			ret.setServiceCategoryServiceEntail(vo.getServiceCategoryServiceEntail());
			ret.setCbQ16ProviderOutreachInd(vo.getCbQ16ProviderOutreachInd());
			ret.setCbQ17ProviderOutreachTxt(vo.getCbQ17ProviderOutreachTxt());
			ret.setServiceCatQuestionsFlag("Y");
		}
		//Co-Branding Partner Form 17-question enhancement end
		
		// State of Incorporation
		// Update of Legal Entity Address information allowed (see SUC)
		// This is going to be a can of worms (but the SUC rules)
		// legalEntity.setUsStateOfIncorporation(getSelectedUsState(vo.getStateOfIncorporation()));
		legalEntity.setUsStateOfIncorporation(getSelectedUsState(vo.getStateOfIncorporation().getUsStateCd()));
		// Is this the right way to do this? Or will it trigger an UPDATE
		// regardless
		// (simply
		/// because we are calling the setWhatever() method)?
		legalEntity.setStreet1Addr(santizeInput(vo.getAddress1()));
		legalEntity.setStreet2Addr(santizeInput(vo.getAddress2()));
		legalEntity.setCityNm(santizeInput(vo.getCity()));
		legalEntity.setUsPstlCd(santizeInput(vo.getZipCode()));
		legalEntity.setUsState(getSelectedUsState(vo.getState().getUsStateCd()));
		legalEntity.setPhoneNum(santizeInput(vo.getPhone()));
		legalEntity.setDunsNum(santizeInput(vo.getDandbNumber()));
		legalEntity.setWebstUrl(santizeInput(vo.getCompanyWebSite()));
		legalEntity.setBusinessType(getSelectedBusinessType(vo.getBusinessType().getBusTypCd()));
		// Co-Branding Partner Form 17-question enhancement: form no longer
		// collects Group Account Type. Skip if not provided to avoid NPE and
		// to preserve any existing value on the LegalEntity (legacy data).
		if (vo.getGroupAccountType() != null
				&& vo.getGroupAccountType().getGrpAcctTypCd() != null
				&& !vo.getGroupAccountType().getGrpAcctTypCd().isEmpty()
				&& !"0".equals(vo.getGroupAccountType().getGrpAcctTypCd())) {
			legalEntity.setGroupAccountType(getSelectedGroupAccountType(vo.getGroupAccountType().getGrpAcctTypCd()));
		}
		legalEntity.setCreateTs(now);
		legalEntity.setCreatedBy(santizeInput(vo.getPortalUser()));
		legalEntity.setUpdateTs(now);
		legalEntity.setUpdatedBy(santizeInput(vo.getPortalUser()));

		byte b2 = 0;
		byte isTpa = new Byte(b2);
		if (vo.getIsTpa().equals(BRPConstants.YES_FLAG)) {
			b2 = 1;
			isTpa = new Byte(b2);
		}
		legalEntity.setTpaInd(isTpa);

		String brandDescription = santizeInput(vo.getCoBrandDescription());
		ret.setBrandUsageDesc(brandDescription);
		ret.setCreateTs(now);
		ret.setUpdateTs(now);
		ret.setCreatedBy(santizeInput(vo.getPortalUser()));
		ret.setUpdatedBy(santizeInput(vo.getPortalUser()));
		ret.setLegalEntity(legalEntity);

		// Handling attachments
		setAttachmentsToModelObject(vo, ret);
		ret.setBrandRqstUid(vo.getBrandRqstUid());
		ret.setSubmitterPlanName(santizeInput(vo.getSubmitterPlanName()));
		ret.setNextBepcMeeting(vo.getNextBepcMeeting());
		ret.setNextPlanMeeting(vo.getNextPlanMeeting());
		ret.setFlagIndependentReview(vo.getFlagIndependentReview());
		
		//BLWBBCBSAUPGD-165 changes begin
		ret.setIntlParentBrandRqstUid(vo.getIntlParentBrandRqstUid());
		//BLWBBCBSAUPGD-165 changes end
		DateFormat df = new SimpleDateFormat("MM/dd/yyyy");
		ret.setRequestedResponseDate(null);
		try {
			ret.setRequestedResponseDate((null != vo.getRequestedResponseDate())? df.parse(vo.getRequestedResponseDate()) : null);
		} catch (ParseException e) {
			e.printStackTrace();
		}
		
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return ret;
	}
	
	public BrandRequest fromValueObject(GeneralBrandRequestVo vo) throws ServiceException {
		BrandRequest ret = new BrandRequest();
		Date now = new Date();
		// Map the fields
		ret.setRequestCategory(requestCategoryService.findById(vo.getRequestCategory().getRqstCtgyUid()));
		ret.setBrandUsageDesc(vo.getCoBrandDescription());
		ret.setCreateTs(now);
		ret.setUpdateTs(now);
		ret.setInqRqstInd((byte) 0);
		ret.setCreatedBy(vo.getPortalUser());
		ret.setUpdatedBy(vo.getPortalUser());
		ret.setStatus(1);
		ret.setEmailId(vo.getSubmitterEmail());
		// Handling attachments
		setAttachmentsToModelObject(vo, ret);
		return ret;
	}

	public BrandRequest fromValueObject(GeneralBrandInquiryVo vo) throws ServiceException {
		BrandRequest ret = new BrandRequest();
		Date now = new Date();
		ret.setRequestCategory(requestCategoryService.findById(vo.getRequestCategory().getRqstCtgyUid()));
		ret.setBrandUsageDesc(vo.getCoBrandDescription());
		ret.setCreateTs(now);
		ret.setUpdateTs(now);
		ret.setInqRqstInd((byte) 1);
		ret.setCreatedBy(vo.getPortalUser());
		ret.setUpdatedBy(vo.getPortalUser());
		ret.setStatus(1);
		// Handling attachments
		setAttachmentsToModelObject(vo, ret);
		return ret;
	}

	/**
	 * Maps the specified Brand Request domain object (probably from the DB) to a
	 * Brand Request Value Object (probably for display).
	 * 
	 * @param source
	 * @return
	 */
	public BrandRequestVo toValueObject(BrandRequest source) {
		String userDetailsCreatedBy= getUserDetails(source.getCreatedBy());
		BrandRequestVo ret = new BrandRequestVo();
		DateFormat df = new SimpleDateFormat(BRPConstants.MM_DD_YYYY);
		// Map field-by-field for display (probably, not that we care)
		ret.setCreatedBy(source.getCreatedBy());
		//ret.setCreatedBy(userDetailsCreatedBy);
		ret.setStatus(source.getStatus());
		ret.setAddress1(source.getLegalEntity().getStreet1Addr());
		ret.setAddress2(source.getLegalEntity().getStreet2Addr());
		ret.setBrandRequestBcbsaSupport(source.getBrandRequestBcbsaSupport());
		BusinessTypeVo businessTypeVo = new BusinessTypeVo();
		BusinessType businessType = source.getLegalEntity().getBusinessType();
		if (businessType != null) {
			businessTypeVo.setBusTypCd(businessType.getBusTypCd());
			businessTypeVo.setBusTypDesc(businessType.getBusTypDesc());
		}
		ret.setBusinessType(businessTypeVo);
		ret.setCity(source.getLegalEntity().getCityNm());
		ret.setCoBrandDescription(source.getBrandUsageDesc());
		ret.setRequestedResponseDate((null != source.getRequestedResponseDate())?df.format(source.getRequestedResponseDate()) : "");
		CobrandReviewTypeVo cobrandReviewTypeVo = new CobrandReviewTypeVo();
		cobrandReviewTypeVo.setCobrandRevwTypNm(source.getCobrandReviewType().getCobrandRevwTypNm());
		cobrandReviewTypeVo.setCobrandRevwTypUid(source.getCobrandReviewType().getCobrandRevwTypUid());
		ret.setCobrandReviewType(cobrandReviewTypeVo);
		
		CobrandRenewalType cobrandRenewalType = new CobrandRenewalType();
		if(source.getCobrandRenewalType()!=null){
			cobrandRenewalType.setCobrandRenwTypUid(""+source.getCobrandRenewalType().getCobrandRevwTypUid());
			cobrandRenewalType.setCobrandRevwTypNm(""+source.getCobrandRenewalType().getCobrandRevwTypNm());
			cobrandRenewalType.setSelected(true);
			ret.setCobrandRenewalType(cobrandRenewalType);
		}
		
		ret.setCompanyWebSite(source.getLegalEntity().getWebstUrl());
		ret.setDandbNumber(source.getLegalEntity().getDunsNum());
		GroupAccountType groupAccountType = source.getLegalEntity().getGroupAccountType();
		GroupAccountTypeVo groupAccountTypeVo = null;
		if (groupAccountType != null) {
			groupAccountTypeVo = new GroupAccountTypeVo(groupAccountType.getGrpAcctTypCd(),
					groupAccountType.getGrpAcctTypDesc());
		}
		ret.setGroupAccountType(groupAccountTypeVo);
		String isTpa = BRPConstants.NO_FLAG;
		byte b = source.getLegalEntity().getTpaInd();
		if (b == (byte) 1) {
			isTpa = BRPConstants.YES_FLAG;
		}
		ret.setIsTpa(isTpa);
		String isUnlicensed = BRPConstants.NO_FLAG;
		LegalEntityRelationship legalEntityRelationship = source.getLegalEntityRelationship();
		if (legalEntityRelationship != null) {
			String relationshipCode = legalEntityRelationship.getLegalEntityRelshpCd();
			if (relationshipCode != null && relationshipCode.equals(BRPConstants.AFFILIATE_RELATIONSHIP_CODE)) {
				isUnlicensed = BRPConstants.YES_FLAG;
				//LegalEntity partnerLegalEntity = source.getPartnerLegalEntity();
				LegalEntity partnerLegalEntity = source.getAssocLegalEntity();
				if (partnerLegalEntity != null) {
					Plan plan = partnerLegalEntity.getPlan();
					if (plan != null) {
						PlanVo planVo = new PlanVo(plan.getPlanCd(), plan.getPlanNm());
						ret.setPlan(planVo);
					}
				}

			}

		}
		ret.setIsUnlicensed(isUnlicensed);
		ret.setLegalName(source.getLegalEntity().getLegalNm());
		ret.setLegalNameUid(String.valueOf(source.getLegalEntity().getLegalEntityUid()));
		ret.setPhone(source.getLegalEntity().getPhoneNum());
		//for textarea content
		ret.setCbStrategicDecisionFact(source.getCbStrategicDecisionFact());
		//for enter here text box
		ret.setCbStrategicRenewRational(source.getCbStrategicRenewRational());
		//for bcbsa support list
		List<CoBrandBcbsaSupportVO> supportList =null;
		try{
			supportList = getCoBrandBcbsaSupportVoTypes();
		}catch(Exception e){
			
		}
		String[] selectedList=source.getBcbaSupportList();
		List<CoBrandBcbsaSupportVO> selectedCobrandList=new ArrayList<CoBrandBcbsaSupportVO>();
		if(selectedList!=null){
		for(String id:selectedList){
			for(CoBrandBcbsaSupportVO supportVo:supportList){
				if(supportVo.getcOBRANDBCBSASupportUID().toString().equals(id)){
					selectedCobrandList.add(supportVo);
				}
			}
		}
		}
		
		
		//cobrandReviewTypeName=cobrandReviewTypes.get(""+ cobrandReviewType.getCobrandRevwTypUid().toString());
		Set duplicates=new HashSet();
		ret.setCoBrandBcbsaSupportList(source.getBcbaSupportList());
		if(source.getBrandRequestBcbsaSupport()!=null){
		for (BrandRequestBcbsaSupport bcbsasupport : source.getBrandRequestBcbsaSupport()) {
			Integer cobrandUId = bcbsasupport.getCoBrandBcbsaSupport().getCOBRANDBCBSASupportUID();
			String cobrandDesc =String.valueOf(bcbsasupport.getCoBrandBcbsaSupport().getCoBrandBcbsaSupportDesc());
			CoBrandBcbsaSupportVO covo=new CoBrandBcbsaSupportVO();
			covo.setcOBRANDBCBSASupportUID(cobrandUId);
			covo.setCoBrandBcbsaSupportDesc(cobrandDesc);
			if(!duplicates.contains(cobrandUId)){
			selectedCobrandList.add(covo);
			}
			duplicates.add(cobrandUId);
			
		}
		}
		ret.setSelectedBcbaSupport(selectedCobrandList);
		//ret.setbrand
		//for cobrand file name display
		//sret.setfi
		List<ServiceCategoryVo> serviceCategories = new ArrayList<>();
		int arrayIndex = 0;
		for (BrandRequestServiceCategory category : source.getBrandRequestServiceCategories()) {
			String srvcCtgyUid = String.valueOf(category.getServiceCategory().getSrvcCtgyUid());
			String serviceCategoryName = category.getServiceCategory().getSrvcCtgyNm();
			if (serviceCategoryName.equals(BRPConstants.OTHER)) {
				ret.setOthSrvcCtgyNm(category.getOthSrvcCtgyNm());
			}
			ServiceCategoryVo scvo = new ServiceCategoryVo(srvcCtgyUid, serviceCategoryName);
			serviceCategories.add(scvo);
		}
		ret.setBrandRqstServiceCategories(serviceCategories);
		//Co-Branding Partner Form 17-question enhancement start
		//Q1-Q9 Brand Questions - always loaded for display
		ret.setCbQ1LegalNameCnfrmd(source.getCbQ1LegalNameCnfrmd());
		ret.setCbQ2DebitCardInd(source.getCbQ2DebitCardInd());
		ret.setCbQ2LicenseAgmtDt(source.getCbQ2LicenseAgmtDt());
		ret.setCbQ3ClientListInd(source.getCbQ3ClientListInd());
		ret.setCbQ3ExceptionAckInd(source.getCbQ3ExceptionAckInd());
		ret.setCbQ4BrandMisuseInd(source.getCbQ4BrandMisuseInd());
		ret.setCbQ4MisuseLinksTxt(source.getCbQ4MisuseLinksTxt());
		ret.setCbQ4MisuseContactTxt(source.getCbQ4MisuseContactTxt());
		ret.setCbQ4MisuseAckInd(source.getCbQ4MisuseAckInd());
		ret.setCbQ5NameLogoInfrngInd(source.getCbQ5NameLogoInfrngInd());
		ret.setCbQ5InfrngLinksTxt(source.getCbQ5InfrngLinksTxt());
		ret.setCbQ5InfrngContactTxt(source.getCbQ5InfrngContactTxt());
		ret.setCbQ5InfrngAckInd(source.getCbQ5InfrngAckInd());
		ret.setCbQ6FinlStableInd(source.getCbQ6FinlStableInd());
		ret.setCbQ7FelonyInd(source.getCbQ7FelonyInd());
		ret.setCbQ8NotOnListInd(source.getCbQ8NotOnListInd());
		ret.setCbQ9ReputationInd(source.getCbQ9ReputationInd());

		//Q10-Q17 IPP Questions
		ret.setCbQ10InterPlanExecTxt(source.getCbQ10InterPlanExecTxt());
		ret.setCbQ11OtherTxt(source.getCbQ11OtherTxt());
		ret.setCbQ12TelehealthSvcInd(source.getCbQ12TelehealthSvcInd());
		ret.setCbQ13VirtualOnlyInd(source.getCbQ13VirtualOnlyInd());
		ret.setCbQ16ProviderOutreachInd(source.getCbQ16ProviderOutreachInd());
		ret.setCbQ17ProviderOutreachTxt(source.getCbQ17ProviderOutreachTxt());

		// Existing service-category-question fields - kept for both new (Q11/Q14/Q15)
		// and legacy display
		if (source.getServiceCategoryBlueBenefit() != null
				|| source.getServiceCategoryNationalAccountMember() != null
				|| source.getServiceCategoryServiceEntail() != null) {
			ret.setServiceCatQuestionsFlag("Y");
			ret.setServiceCategoryBlueBenefit(source.getServiceCategoryBlueBenefit());
			ret.setServiceCategoryNationalAccountMember(source.getServiceCategoryNationalAccountMember());
			ret.setServiceCategoryServiceEntail(source.getServiceCategoryServiceEntail());
		}

		// Legacy criteria fields - still loaded for old records so My History /
		// Workqueue can display them. New records will have these as null.
		ret.setDemoFinancial(source.getDemoFinancial());
		ret.setNoFelonyRecord(source.getNoFelonyRecord());
		ret.setProhibitatedCompany(source.getProhibitatedCompany());
		ret.setReputationBrand(source.getReputationBrand());
		ret.setNoMisuseOfBrands(source.getNoMisuseOfBrands());
		//Co-Branding Partner Form 17-question enhancement end
		
		UsStateVo stateVo = new UsStateVo();
		UsState state = source.getLegalEntity().getUsState();
		if (state != null) {
			stateVo.setUsStateCd(state.getUsStateCd());
			stateVo.setUsStateNm(state.getUsStateNm());
		}
		ret.setState(stateVo);
		stateVo = new UsStateVo();
		UsState stateOfIncorporation = source.getLegalEntity().getUsStateOfIncorporation();
		if (stateOfIncorporation != null) {
			stateVo.setUsStateCd(stateOfIncorporation.getUsStateCd());
			stateVo.setUsStateNm(stateOfIncorporation.getUsStateNm());
		}
		ret.setStateOfIncorporation(stateVo);
		Set<LegalEntityTradeName> legalEntityTradeNames = source.getLegalEntity().getLegalEntityTradeNames();
		String[] tradeNames = new String[legalEntityTradeNames.size()];
		arrayIndex = 0;
		for (LegalEntityTradeName tradeName : legalEntityTradeNames) {
			tradeNames[arrayIndex++] = tradeName.getId().getTradeNm();
		}
		ret.setTradeNames(tradeNames);
		ret.setZipCode(source.getLegalEntity().getUsPstlCd());

		// Attachments
		Set<UserUploadFile> attachments = source.getUserUploadFiles();
		Set<UserUploadCobrandSample> attachements1=source.getUserUploadCobrandSample();
		setAttachmentsToValueObject(ret, attachments);
		setAttachmentsToValueObjectCobrand(ret, attachements1);
		ret.setBrandRqstUid(source.getBrandRqstUid());
		//ret.setPortalUser(source.getCreatedBy());
		ret.setPortalUser(userDetailsCreatedBy);
		// TODO: Move Date formatting operations to a utility class

		ret.setCreateTs(df.format(source.getCreateTs()));
		if(source.getCbRenewalDate()!=null)
		ret.setCbRenewalDate(df.format(source.getCbRenewalDate()));
		if(source.getCbSampleUploadDate()!=null)
		ret.setCbSampleUploadDate(df.format(source.getCbSampleUploadDate()));
		if(source.getCbSampleUploadActualDate()!=null)
		ret.setCbSampleUploadActualDate(df.format(source.getCbSampleUploadActualDate()));
		//ret.setUpdatedBy(source.getUpdatedBy());
		String userDetailsUpdatedBy= getUserDetails(source.getUpdatedBy());
		ret.setUpdatedBy(userDetailsUpdatedBy);
		ret.setUpdatedByOriginal(source.getUpdatedBy());
	
		ret.setUpdateTs(df.format(source.getUpdateTs()));
		ret.setSubmitterPlanName(source.getSubmitterPlanName());
		ret.setNextBepcMeeting(source.getNextBepcMeeting());
		ret.setNextPlanMeeting(source.getNextPlanMeeting());
		ret.setFlagIndependentReview(source.getFlagIndependentReview());
		ret.setGeneralComments(source.getGeneralComments());
		ret.setSummaryTxt(source.getSummaryTxt());
		ret.setBlueWebComments(source.getBlueWebComments());
		//BLWBBCBSAUPGD-165 changes begin
		ret.setParentBrandRqstUid(source.getParentBrandRqstUid());
		ret.setIntlParentBrandRqstUid(source.getIntlParentBrandRqstUid());
		//BLWBBCBSAUPGD-165 changes end
		return ret;
	}

	public GeneralBrandRequestVo toGeneralBrandRequestValueObject(BrandRequest source) {
		// Map the fields
		GeneralBrandRequestVo ret = new GeneralBrandRequestVo();
		// Get the nested RequestCategoryVo - creates if does not exist
		RequestCategory requestCategory = source.getRequestCategory();
		// Map the RequestCategory Vo
		RequestCategoryVo requestCategoryVo = ret.getRequestCategory();
		requestCategoryVo.setCreatedBy(requestCategory.getCreatedBy());
		requestCategoryVo.setCreateTs(requestCategory.getCreateTs());
		requestCategoryVo.setRqstCtgyNm(requestCategory.getRqstCtgyNm());
		requestCategoryVo.setRqstCtgyUid(requestCategory.getRqstCtgyUid());
		requestCategoryVo.setUpdatedBy(requestCategory.getUpdatedBy());
		requestCategoryVo.setUpdateTs(requestCategory.getUpdateTs());
		// Message (can we figure out what to call it? LOL)
		ret.setCoBrandDescription(source.getBrandUsageDesc());
		// Other stuff
		ret.setCreateTs(source.getCreateTs().toString());
		ret.setUpdateTs(source.getUpdateTs().toString());
		String userDetailsCreatedBy= getUserDetails(source.getCreatedBy());
		ret.setCreatedBy(userDetailsCreatedBy);
		String userDetailsUpdatedBy= getUserDetails(source.getUpdatedBy());
		ret.setUpdatedBy(userDetailsUpdatedBy);
		
		//ret.setCreatedBy(source.getCreatedBy());
		//ret.setUpdatedBy(source.getUpdatedBy());
		// Set Attachment info
		setAttachmentsToValueObject(ret, source.getUserUploadFiles());
		return ret;
	}

	private BrandRequestVo setAttachmentsToValueObject(BrandRequestVo brandRequestVo, Set<UserUploadFile> attachments) {
		if (attachments != null && !attachments.isEmpty()) {
			List<DLFileEntry> dlFileList = userUploadFileService.getLiferayFiles(attachments);
			if (dlFileList != null && !dlFileList.isEmpty()) {
				List<FileAttachmentVo> fileVoList = new ArrayList<>();
				for (DLFileEntry file : dlFileList) {
					FileAttachmentVo attachmentVo = new FileAttachmentVo(String.valueOf(file.getFileEntryId()), file.getTitle(),
							file.getDescription(),"User");
					fileVoList.add(attachmentVo);
				}
				brandRequestVo.setAttachmentList(fileVoList);

			}
			 
		}
		return brandRequestVo;
	}
	

	private BrandRequestVo setAttachmentsToValueObjectCobrand(BrandRequestVo brandRequestVo, Set<UserUploadCobrandSample> attachments) {
		if (attachments != null && !attachments.isEmpty()) {
		
			
			List<DLFileEntry> dlFileList=userUploadCobrandSampleService.getLiferayFiles(attachments);
			if (dlFileList != null && !dlFileList.isEmpty()) {
				List<FileAttachmentVo> fileVoList = new ArrayList<>();
				for (DLFileEntry file : dlFileList) {
					FileAttachmentVo attachmentVo = new FileAttachmentVo(String.valueOf(file.getFileEntryId()), file.getTitle(),
							file.getDescription(),"Cobrand");
					
					fileVoList.add(attachmentVo);
				}
				if(brandRequestVo.getAttachmentList()!=null){
					brandRequestVo.getAttachmentList().addAll(fileVoList);
				}else
				brandRequestVo.setAttachmentList(fileVoList);

			}
		}
		return brandRequestVo;
	}

	public void setAttachmentsToModelObject(BrandRequestVo vo, BrandRequest ret) {
		List<FileAttachmentVo> attachmentList = vo.getAttachmentList();
		if (attachmentList != null && !attachmentList.isEmpty()) {
			Date now = new Date();
			Set<UserUploadFile> uploadFileSet = new HashSet<>();
			Set<UserUploadCobrandSample> uploadcobrandFileSet = new HashSet<>();
			for (FileAttachmentVo attachmentInfo : attachmentList) {
				if (attachmentInfo.getFileId() != null && attachmentInfo.getFileName() != null && "User".equalsIgnoreCase(attachmentInfo.getType())) {
					UserUploadFile file = new UserUploadFile();
					file.setBrandRequest(ret);
					// What is this value going to be?
					Date actvtyStartTs = now;
					UserUploadFilePK pk = new UserUploadFilePK(file.getBrandRequest().getBrandRqstUid(), actvtyStartTs,
							attachmentInfo.getFileId());
					file.setId(pk);
					file.setCreatedBy(vo.getPortalUser());
					file.setUpdatedBy(vo.getPortalUser());
					file.setCreateTs(now);
					file.setFileType(attachmentInfo.getFileType());
					file.setUpdateTs(now);
					uploadFileSet.add(file);
				} if (attachmentInfo.getFileId() != null && attachmentInfo.getFileName() != null && "Cobrand".equalsIgnoreCase(attachmentInfo.getType())) {
					UserUploadCobrandSample cobrandFile=new UserUploadCobrandSample();
					cobrandFile.setBrandRequest(ret);
					Date actvtyStartTs = now;
					UserUploadCobrandSamplePK cobrandPk=new UserUploadCobrandSamplePK(
							cobrandFile.getBrandRequest().getBrandRqstUid(), actvtyStartTs,
							attachmentInfo.getFileId());
					cobrandFile.setUserUploadCobrandSamplePK(cobrandPk);
					cobrandFile.setCreatedBy(vo.getPortalUser());
					cobrandFile.setUpdatedBy(vo.getPortalUser());
					cobrandFile.setCreateTs(now);
					cobrandFile.setUpdateTs(now);
					//cobrandFile.setFileType(attachmentInfo.getFileType());
					uploadcobrandFileSet.add(cobrandFile);
				}
			}
			ret.setUserUploadCobrandSample(uploadcobrandFileSet);
			ret.setUserUploadFiles(uploadFileSet);
		}
	}

	/**
	 * Returns a new BrandRequestFormModel object
	 * 
	 * @return
	 */
	public BrandRequestVo getBrandRequestFormModel() {
		// No brainer
		BrandRequestVo brandRequestVo = new BrandRequestVo();
		brandRequestVo.setIsUnlicensed("No");
		brandRequestVo.setIsTpa("No");
		return brandRequestVo;
	}

	public GeneralBrandRequestVo getGeneralBrandRequestFormModel() {
		return new GeneralBrandRequestVo();
	}

	/**
	 * Returns a List of BusinessType objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<BusinessType> getBusinessTypes() throws ServiceException {
		if (businessTypes == null) {
			businessTypes = businessTypeService.fetchAll();
		}
		return businessTypes;
	}

	/**
	 * Returns a List of CobrandReviewType objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<CobrandReviewType> getCobrandReviewTypes(String activeFlag) throws ServiceException {
		/*if (cobrandReviewTypes == null) {
			cobrandReviewTypes = cobrandReviewTypeService.getCoBrandTypesWithOrder(activeFlag);
		}*/
		cobrandReviewTypes = cobrandReviewTypeService.getCoBrandTypesWithOrder(activeFlag);
		return cobrandReviewTypes;
	}


	/**
	 * Returns a List of active CobrandReviewType objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */

	public List<BusinessType> getActiveBusinessReviewTypes() throws ServiceException {
		if (businessTypes == null) {
			businessTypes = businessTypeService.getActiveBusinessTypes("Y");
		}
		return businessTypes;
	}


	/**
	 * Returns a List of active CobrandReviewType objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<CobrandReviewType> getActiveCobrandReviewTypes() throws ServiceException {
		/*if (cobrandReviewTypes == null) {
			cobrandReviewTypes = cobrandReviewTypeService.getActiveCoBrandTypes("Y");
		}*/
		cobrandReviewTypes = cobrandReviewTypeService.getActiveCoBrandTypes("Y","Y");
		return cobrandReviewTypes;
	}


	public Map<String,String> getActiveCobrandReviewTypesMap() throws ServiceException {

		if(cobrandReviewTypesMap==null){
			cobrandReviewTypesMap=new HashMap<String,String>();
			List<CobrandReviewType> cobrandReviewTypesList =getActiveCobrandReviewTypes();
			for(CobrandReviewType type:cobrandReviewTypesList){
				cobrandReviewTypesMap.put(""+type.getCobrandRevwTypUid(), type.getCobrandRevwTypNm());
			}
		}


		return  cobrandReviewTypesMap;
	}

	/**
	 * Returns a List of CobrandReviewType objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<CobrandRenewalType> getCobrandRenewalTypes() throws ServiceException {
		if (cobrandRenewalTypes == null) {
			cobrandRenewalTypes=new ArrayList<CobrandRenewalType>();
			cobrandRenewalTypesMap=new HashMap<String,String>();
			List<CobrandReviewType> cobrandReviewTypes = cobrandReviewTypeService.getActiveCoBrandTypes("Y");
			Iterator<CobrandReviewType> it=cobrandReviewTypes.iterator();
			while(it.hasNext()){
				CobrandReviewType reviewType=it.next();
				if(reviewType.getCobrandRevwTypNm().equalsIgnoreCase("Select") ||
						reviewType.getCobrandRevwTypNm().equalsIgnoreCase("Premier") ||
						reviewType.getCobrandRevwTypNm().equalsIgnoreCase("Strategic")){
					CobrandRenewalType renwalType=new CobrandRenewalType();
					renwalType.setCobrandRevwTypNm(reviewType.getCobrandRevwTypNm()+"- Renewal");
					renwalType.setCobrandRenwTypUid(""+reviewType.getCobrandRevwTypUid());
					cobrandRenewalTypes.add(renwalType);
					cobrandRenewalTypesMap.put(""+reviewType.getCobrandRevwTypUid(), reviewType.getCobrandRevwTypNm());
				}
			}

		}
		return cobrandRenewalTypes;
	}

	public Map<String,String> getCobrandRenewalTypesMap() throws ServiceException {
		return cobrandRenewalTypesMap;

	}

	/**
	 * Returns a List of GroupAccountType objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<GroupAccountType> getGroupAccountTypes() throws ServiceException {
		if (groupAccountTypes == null) {
			groupAccountTypes = groupAccountTypeService.fetchAll();
		}
		return groupAccountTypes;
	}

	/**
	 * Returns a List of ServiceCategory objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<ServiceCategory> getServiceCategories() throws ServiceException {
		if (serviceCategories == null) {
			serviceCategories = serviceCategoryService.fetchAll();
		}
		return serviceCategories;
	}

	/**
	 * Returns a List of UsState objects from the Service layer.
	 * 
	 * @return
	 * @throws ServiceException
	 */
	public List<UsState> getUsStates() throws ServiceException {
		if (usStates == null) {
			usStates = usStateService.fetchAll();
		}
		return usStates;
	}

	/**
	 * TODO: This method needs to be modified so as to return only the plans that
	 * are applicable for the current service area.
	 * 
	 * Returns a List of Plan objects from the Service layer
	 * 
	 * @return plans
	 * @throws ServiceException
	 */
	public List<Plan> getPlans() throws ServiceException {
		if (plans == null) {
			plans = planService.fetchAll();
		}
		return plans;
	}

	/**
	 * Returns a List of RequestCategory objects from the service tier.
	 * 
	 * @return List<RequestCategory> - the List of RequestCategory objects
	 * 
	 * @throws ServiceException
	 */
	public List<RequestCategory> getRequestCategories(Map<String, Object> paramMap) throws ServiceException {
		List<RequestCategory> requestCategories = new ArrayList<RequestCategory>();
		try {
			requestCategories = requestCategoryService.fetchRequestCategoriesByCode(paramMap);
		} catch (ServiceException e) {

		}
		return requestCategories;
	}

	// TO BE REFACTORED
	private List<ServiceCategory> getSelectedServiceCategories(String[] serviceCategoriesArray) {
		List<ServiceCategory> ret = new ArrayList<ServiceCategory>();
		if (serviceCategoriesArray != null && serviceCategoriesArray.length > 0) {
			for (String sc : serviceCategoriesArray) {
				for (ServiceCategory serviceCategory : serviceCategories) {
					if (sc != null) {
						if (serviceCategory.getSrvcCtgyUid() == Long.valueOf(sc)) {
							ret.add(serviceCategory);
							break;
						}
					}
				}
			}
		}
		return ret;
	}

	private CobrandReviewType getSelectedCobrandReviewType(Long long1) {
		CobrandReviewType selectedCobrandReviewType = null;
		for (CobrandReviewType crt : cobrandReviewTypes) {
			if (crt.getCobrandRevwTypUid() == long1) {
				selectedCobrandReviewType = crt;
				break;
			}
		}
		return selectedCobrandReviewType;
	}

	private UsState getSelectedUsState(String stateCode) {
		UsState selectedState = null;
		for (UsState state : usStates) {
			if (state.getUsStateCd().equals(stateCode)) {
				selectedState = state;
				break;
			}
		}
		return selectedState;
	}

	private BusinessType getSelectedBusinessType(String businessType) {
		if(null == businessType) return null;
		BusinessType selectedBusinessType = null;
		for (BusinessType bt : businessTypes) {
			if (bt.getBusTypCd().equals(businessType)) {
				selectedBusinessType = bt;
				break;
			}
		}
		return selectedBusinessType;
	}

	private GroupAccountType getSelectedGroupAccountType(String groupAccountTypeDesc) {
		GroupAccountType selectedGroupAccountType = null;
		for (GroupAccountType gat : groupAccountTypes) {
			if (gat.getGrpAcctTypCd().equals(groupAccountTypeDesc)) {
				selectedGroupAccountType = gat;
				break;
			}
		}
		return selectedGroupAccountType;
	}

	/**
	 * Co-Branding Partner Form 17-question enhancement.
	 *
	 * On the form, child/dependent fields are hidden but their entered values are
	 * intentionally preserved when a parent Yes/No is toggled (so the user does not
	 * lose data when flipping back and forth). The side effect is that a stale child
	 * value can still be submitted even though the final parent answer no longer
	 * warrants it (e.g. Q2 date entered, then Q2 switched to No; or a full Q11=CLAIM
	 * cascade filled in, then Q11 switched to CARVEOUT). This method clears every
	 * orphaned child value on the VO based on the final parent answers so the
	 * persisted record is internally consistent. Call this on the submit and
	 * save-for-later paths before mapping the VO to the entity.
	 */
	private void sanitizeConditionalAnswers(BrandRequestVo vo) {
		if (vo == null) {
			return;
		}

		// ----- Brand Questions (Q2-Q5) simple parent -> child -----

		// Q2: license date only valid when Q2 = Y
		if (!"Y".equalsIgnoreCase(vo.getCbQ2DebitCardInd())) {
			vo.setCbQ2LicenseAgmtDt(null);
		}

		// Q3: exception acknowledgement only valid when Q3 = Y
		if (!"Y".equalsIgnoreCase(vo.getCbQ3ClientListInd())) {
			vo.setCbQ3ExceptionAckInd(null);
		}

		// Q4: links / contact / ack only valid when Q4 = Y
		if (!"Y".equalsIgnoreCase(vo.getCbQ4BrandMisuseInd())) {
			vo.setCbQ4MisuseLinksTxt(null);
			vo.setCbQ4MisuseContactTxt(null);
			vo.setCbQ4MisuseAckInd(null);
		}

		// Q5: links / contact / ack only valid when Q5 = Y
		if (!"Y".equalsIgnoreCase(vo.getCbQ5NameLogoInfrngInd())) {
			vo.setCbQ5InfrngLinksTxt(null);
			vo.setCbQ5InfrngContactTxt(null);
			vo.setCbQ5InfrngAckInd(null);
		}

		// ----- Inter-Plan Policy section (Q10 -> Q17) -----
		// If the selected service categories do not trigger the IPP section, none of
		// Q10-Q17 (nor the reused Q11/Q14/Q15 columns) should carry a value.
		boolean ippTriggered = "Y".equalsIgnoreCase(vo.getServiceCatQuestionsFlag());
		if (!ippTriggered) {
			vo.setCbQ10InterPlanExecTxt(null);
			vo.setServiceCategoryBlueBenefit(null);
			vo.setCbQ11OtherTxt(null);
			vo.setCbQ12TelehealthSvcInd(null);
			vo.setCbQ13VirtualOnlyInd(null);
			vo.setServiceCategoryNationalAccountMember(null);
			vo.setServiceCategoryServiceEntail(null);
			vo.setCbQ16ProviderOutreachInd(null);
			vo.setCbQ17ProviderOutreachTxt(null);
			return;
		}

		// ----- Inter-Plan Policy cascade (Q11 -> Q17) -----
		// Determine, from the final answers, which downstream questions are valid.
		// Anything not valid is cleared. Q11 uses the reused SRVC_BLUE_BENEFITS value
		// (CARVEOUT / CLAIM / OTHER); Q14/Q15 use the other reused columns.

		String q11 = vo.getServiceCategoryBlueBenefit();          // CARVEOUT / CLAIM / OTHER
		boolean q11Other = "OTHER".equalsIgnoreCase(q11);
		boolean q11Claim = "CLAIM".equalsIgnoreCase(q11);

		// Q11 "Other" free text only valid when Q11 = OTHER
		if (!q11Other) {
			vo.setCbQ11OtherTxt(null);
		}

		// Q12 only valid when Q11 = CLAIM
		if (!q11Claim) {
			vo.setCbQ12TelehealthSvcInd(null);
		}

		String q12 = vo.getCbQ12TelehealthSvcInd();
		boolean q12Yes = q11Claim && "Y".equalsIgnoreCase(q12);
		boolean q12No  = q11Claim && "N".equalsIgnoreCase(q12);

		// Q13 only valid when Q11 = CLAIM and Q12 = Y
		if (!q12Yes) {
			vo.setCbQ13VirtualOnlyInd(null);
		}

		String q13 = vo.getCbQ13VirtualOnlyInd();
		boolean q13No = q12Yes && "N".equalsIgnoreCase(q13);

		// Q14/Q15/Q16 (and Q17) are valid only on these terminal paths:
		//   - Q11 = OTHER
		//   - Q11 = CLAIM and Q12 = N
		//   - Q11 = CLAIM and Q12 = Y and Q13 = N
		boolean q14Onward = q11Other || q12No || q13No;

		if (!q14Onward) {
			// reused columns for Q14 (national account) and Q15 (services entail)
			vo.setServiceCategoryNationalAccountMember(null);
			vo.setServiceCategoryServiceEntail(null);
			vo.setCbQ16ProviderOutreachInd(null);
			vo.setCbQ17ProviderOutreachTxt(null);
		} else {
			// Q17 detail only valid when Q16 = Y
			if (!"Y".equalsIgnoreCase(vo.getCbQ16ProviderOutreachInd())) {
				vo.setCbQ17ProviderOutreachTxt(null);
			}
		}
	}

	/*
	 * private RequestCategory getSelectedRequestCategory(RequestCategoryVo
	 * requestCategory) { RequestCategory ret = null; for (RequestCategory rc :
	 * getRequestCategories().get(0)) { if
	 * (rc.getRqstCtgyUid().equals(requestCategory.getRqstCtgyUid())) { ret = rc;
	 * break; } } return ret;
	 * 
	 * }
	 */

	public GeneralBrandInquiryVo getGeneralBrandInquiryFormModel() {
		return new GeneralBrandInquiryVo();
	}

	/**
	 * Maps the specified Brand Request domain object (probably from the DB) to a
	 * Brand Request Value Object (probably for display).
	 * 
	 * @param source
	 * @return
	 */
	public NonCoBrandRequestVo toGeneralBrandReqDisplay(BrandRequest source) {
		NonCoBrandRequestVo ret = new NonCoBrandRequestVo();
		BrandRequestVo tempVo = new BrandRequestVo();
		ret.setBrandRqstUid(source.getBrandRqstUid());
		ret.setCreatedBy(source.getCreatedBy());
		ret.setStatus(source.getStatus());
		ret.setUpdatedBy(source.getUpdatedBy());
		Set<UserUploadFile> attachments = source.getUserUploadFiles();
		setAttachmentsToValueObject(tempVo, attachments);
		ret.setAttachmentList(tempVo.getAttachmentList());
		DateFormat df = new SimpleDateFormat(BRPConstants.MM_DD_YYYY);
		ret.setCreateTs(df.format(source.getCreateTs()));
		ret.setUpdateTs(df.format(source.getUpdateTs()));
		ret.setDescription(source.getBrandUsageDesc());
		ret.setRequestCategory(source.getRequestCategory().getRqstCtgyNm());
		ret.setGeneralComments(source.getGeneralComments());
		ret.setSummaryTxt(source.getSummaryTxt());
		ret.setSubmitterPlanName(source.getSubmitterPlanName());
		ret.setGbrDerivativeApprovalDate(source.getGbrDerivativeApprovalDate());
		ret.setGbrDerivativeRemainderDate(source.getGbrDerivativeRemainderDate());
		ret.setGbrSendRemainder(source.getGbrSendRemainder());
		return ret;
	}

	public BrandRequest fromValueObjectSaveForLater(BrandRequestVo vo) throws ServiceException {
		BrandRequest ret = new BrandRequest();
		Date now = new Date();
		LegalEntity legalEntity = null;
		
		try {
		if(null != vo.getLegalName() && !"".equalsIgnoreCase(vo.getLegalName())){
			String legalName = santizeInput(vo.getLegalName());
			legalEntity = legalEntityService.fetchByName(legalName);
		}
		if (legalEntity == null) {
			legalEntity = new LegalEntity();
			String legalName = santizeInput(vo.getLegalName());
			legalEntity.setLegalNm(legalName);
		}
		byte b = 0;
		byte isUnlicensed = new Byte(b);
		if (null != vo.getIsUnlicensed() && vo.getIsUnlicensed().equals(BRPConstants.YES_FLAG)) {
			b = 1;
			isUnlicensed = new Byte(b);
			String planCode = santizeInput(vo.getPlan().getPlanCd());
			String relationshipCode = BRPConstants.AFFILIATE_RELATIONSHIP_CODE;
			if (planCode != null && !planCode.isEmpty()) {
				// Get the associated Legal Entity by plan code
				LegalEntity associatedLegalEntity = legalEntityService.getLegalEntityByPlanCode(planCode);
				LegalEntityAssociation legalEntityAssociation = new LegalEntityAssociation();
				ret.setAssocLegalEntity(associatedLegalEntity);
				// Get LegalEntityRelationship object
				LegalEntityRelationship relationship = legalEntityRelationshipService.getLegalEntityRelationshipByCode(relationshipCode);
				legalEntityAssociation.setUnlcnsdAffltInd(isUnlicensed);
				legalEntityAssociation.setCreatedBy(santizeInput(vo.getPortalUser()));
				legalEntityAssociation.setCreateTs(now);
				legalEntityAssociation.setUpdatedBy(santizeInput(vo.getPortalUser()));
				legalEntityAssociation.setUpdateTs(now);
				// TODO: Where do we get inactvDt date?
				// legalEntityAssociation.setInactvDt(now);
				legalEntityAssociation.setLegalEntity(legalEntity);
				legalEntityAssociation.setAssociatedLegalEntity(associatedLegalEntity);
				legalEntityAssociation.setLegalEntityRelationship(relationship);
				LegalEntityAssociationPK pk = new LegalEntityAssociationPK();
				pk.setLegalEntityUid(legalEntity.getLegalEntityUid());
				pk.setAsctdLegalEntityUid(associatedLegalEntity.getLegalEntityUid());
				pk.setLegalEntityRelshpCd(relationship.getLegalEntityRelshpCd());
				legalEntityAssociation.setId(pk);
				//ret.setPartnerLegalEntity(associatedLegalEntity);
				ret.setLegalEntityRelationship(relationship);
				List<LegalEntityAssociation> leAssociationList = legalEntityAssociationService.getLegalEntityAssociationsById(pk);
				log.info("Le Association List Size: " + leAssociationList + "---" + ( leAssociationList != null ? leAssociationList.size() : "NULL"));
				if(null != leAssociationList && leAssociationList.size() > 0){
					ret.setLegalEntityAssociation(null);
				} else {
					ret.setLegalEntityAssociation(legalEntityAssociation);
				}

			}
		}
		String[] tradeNames = vo.getTradeNames();
		LinkedHashSet<LegalEntityTradeName> tradeNameSet = new LinkedHashSet<LegalEntityTradeName>();
		if (tradeNames != null && tradeNames.length > 0) {
			for (String str : tradeNames) {
				if (StringUtils.isNotEmpty(str)) {
					str = santizeInput(str);
					LegalEntityTradeName tradeName = new LegalEntityTradeName();
					tradeName.setLegalEntity(legalEntity);
					tradeName.setCreatedBy(santizeInput(vo.getPortalUser()));
					tradeName.setCreateTs(now);
					tradeName.setUpdatedBy(santizeInput(vo.getPortalUser()));
					tradeName.setUpdateTs(now);
					LegalEntityTradeNamePK pk = new LegalEntityTradeNamePK(legalEntity.getLegalEntityUid(), str);
					tradeName.setId(pk);
					tradeNameSet.add(tradeName);
				}
			}
		}
		legalEntity.setLegalEntityTradeNames(tradeNameSet);

		//cobrand RenweRational message
		if(vo.getCbStrategicRenewRational()!=null)
			ret.setCbStrategicRenewRational(santizeInput(vo.getCbStrategicRenewRational()));

		if(vo.getCbStrategicDecisionFact()!=null)
			ret.setCbStrategicDecisionFact(santizeInput(vo.getCbStrategicDecisionFact()));

		// Cobrand Review Type (a.k.a., Service
		ret.setCobrandReviewType(getSelectedCobrandReviewType(vo.getCobrandReviewType().getCobrandRevwTypUid()));

		// Service Categories - there is a M2M relationship between BrandRequest
		/// and ServiceCategory. So we need to create and set the appropriate
		// objects
		/// in the model.
		// int[] serviceCategories = vo.getServiceCategories();
		String[] serviceCategoriesArray = null;
		List<ServiceCategoryVo> serviceCategories = vo.getBrandRqstServiceCategories();
		if (serviceCategories != null && !serviceCategories.isEmpty()) {
			serviceCategoriesArray = new String[serviceCategories.size()];
			int count = 0;
			for (ServiceCategoryVo svo : serviceCategories) {
				String srvcCtgyUid = svo.getSrvcCtgyUid();
				if (StringUtils.isEmpty(srvcCtgyUid)) {
					continue;
				}
				serviceCategoriesArray[count++] = svo.getSrvcCtgyUid();
			}
		}

		List<ServiceCategory> selectedServiceCategories = getSelectedServiceCategories(serviceCategoriesArray);
		Set<BrandRequestServiceCategory> brandRequestServiceCategorySet = new HashSet<>();
		for (ServiceCategory sc : selectedServiceCategories) {
			BrandRequestServiceCategory brsc = new BrandRequestServiceCategory();
			brsc.setCreateTs(now);
			brsc.setCreatedBy(santizeInput(vo.getPortalUser()));
			brsc.setUpdateTs(now);
			brsc.setUpdatedBy(santizeInput(vo.getPortalUser()));
			if (sc.getSrvcCtgyNm().equals(BRPConstants.OTHER)) {
				brsc.setOthSrvcCtgyNm(santizeInput(vo.getOthSrvcCtgyNm()));
			}
			brsc.setBrandRequest(ret);
			brsc.setServiceCategory(sc);
			BrandRequestServiceCategoryPK pk = new BrandRequestServiceCategoryPK(ret.getBrandRqstUid(), sc.getSrvcCtgyUid());
			brsc.setId(pk);
			brandRequestServiceCategorySet.add(brsc);
		}
		ret.setBrandRequestServiceCategories(brandRequestServiceCategorySet);
		// State of Incorporation
		// Update of Legal Entity Address information allowed (see SUC)
		// This is going to be a can of worms (but the SUC rules)
		// legalEntity.setUsStateOfIncorporation(getSelectedUsState(vo.getStateOfIncorporation()));
		legalEntity.setUsStateOfIncorporation(getSelectedUsState(vo.getStateOfIncorporation().getUsStateCd()));
		// Is this the right way to do this? Or will it trigger an UPDATE
		// regardless
		// (simply
		/// because we are calling the setWhatever() method)?
		legalEntity.setStreet1Addr((null != vo.getAddress1())?santizeInput(vo.getAddress1()) : "");
		legalEntity.setStreet2Addr((null != vo.getAddress2())?santizeInput(vo.getAddress2()) : "");
		legalEntity.setCityNm((null != vo.getCity())?santizeInput(vo.getCity()) : "");
		legalEntity.setUsPstlCd((null != vo.getZipCode())?santizeInput(vo.getZipCode()) : "");
		legalEntity.setUsState((null != vo.getState())?getSelectedUsState(vo.getState().getUsStateCd()): null);
		legalEntity.setPhoneNum((null != vo.getPhone())?santizeInput(vo.getPhone()):"");
		legalEntity.setDunsNum((null != vo.getDandbNumber())?santizeInput(vo.getDandbNumber()) : "");
		legalEntity.setWebstUrl(santizeInput(vo.getCompanyWebSite()));
		legalEntity.setBusinessType(getSelectedBusinessType(vo.getBusinessType().getBusTypCd()));
		// Co-Branding Partner Form 17-question enhancement: form no longer
		// collects Group Account Type. Skip if not provided to avoid NPE and
		// to preserve any existing value on the LegalEntity (legacy data).
		if (vo.getGroupAccountType() != null
				&& vo.getGroupAccountType().getGrpAcctTypCd() != null
				&& !vo.getGroupAccountType().getGrpAcctTypCd().isEmpty()
				&& !"0".equals(vo.getGroupAccountType().getGrpAcctTypCd())) {
			legalEntity.setGroupAccountType(getSelectedGroupAccountType(vo.getGroupAccountType().getGrpAcctTypCd()));
		}
		legalEntity.setCreateTs(now);
		legalEntity.setCreatedBy(santizeInput(vo.getPortalUser()));
		legalEntity.setUpdateTs(now);
		legalEntity.setUpdatedBy(santizeInput(vo.getPortalUser()));

		byte b2 = 0;
		byte isTpa = new Byte(b2);
		if (vo.getIsTpa().equals(BRPConstants.YES_FLAG)) {
			b2 = 1;
			isTpa = new Byte(b2);
		}
		legalEntity.setTpaInd(isTpa);

		String brandDescription = santizeInput(vo.getCoBrandDescription());
		ret.setBrandUsageDesc(brandDescription);
		ret.setCreateTs(now);
		ret.setUpdateTs(now);
		ret.setCreatedBy(santizeInput(vo.getPortalUser()));
		ret.setUpdatedBy(santizeInput(vo.getPortalUser()));
		ret.setLegalEntity(legalEntity);

		// Handling attachments
		setAttachmentsToModelObject(vo, ret);
		ret.setBrandRqstUid(vo.getBrandRqstUid());
		ret.setSubmitterPlanName(santizeInput(vo.getSubmitterPlanName()));
		ret.setNextBepcMeeting(vo.getNextBepcMeeting());
		ret.setNextPlanMeeting(vo.getNextPlanMeeting());
		ret.setFlagIndependentReview(vo.getFlagIndependentReview());
		DateFormat df = new SimpleDateFormat("MM/dd/yyyy");
		ret.setRequestedResponseDate(null);
		try {
			ret.setRequestedResponseDate((null != vo.getRequestedResponseDate())? df.parse(vo.getRequestedResponseDate()) : null);
		} catch (ParseException e) {
			e.printStackTrace();
		}
		
		} catch (Exception e) {
			e.printStackTrace();
		}
		//Co-Branding Partner Form 17-question enhancement (save for later) start
		//Clear orphaned child values so a saved draft stays internally consistent.
		sanitizeConditionalAnswers(vo);
		ret.setCbQ1LegalNameCnfrmd(vo.getCbQ1LegalNameCnfrmd());
		ret.setCbQ2DebitCardInd(vo.getCbQ2DebitCardInd());
		ret.setCbQ2LicenseAgmtDt(vo.getCbQ2LicenseAgmtDt());
		ret.setCbQ3ClientListInd(vo.getCbQ3ClientListInd());
		ret.setCbQ3ExceptionAckInd(vo.getCbQ3ExceptionAckInd());
		ret.setCbQ4BrandMisuseInd(vo.getCbQ4BrandMisuseInd());
		ret.setCbQ4MisuseLinksTxt(vo.getCbQ4MisuseLinksTxt());
		ret.setCbQ4MisuseContactTxt(vo.getCbQ4MisuseContactTxt());
		ret.setCbQ4MisuseAckInd(vo.getCbQ4MisuseAckInd());
		ret.setCbQ5NameLogoInfrngInd(vo.getCbQ5NameLogoInfrngInd());
		ret.setCbQ5InfrngLinksTxt(vo.getCbQ5InfrngLinksTxt());
		ret.setCbQ5InfrngContactTxt(vo.getCbQ5InfrngContactTxt());
		ret.setCbQ5InfrngAckInd(vo.getCbQ5InfrngAckInd());
		ret.setCbQ6FinlStableInd(vo.getCbQ6FinlStableInd());
		ret.setCbQ7FelonyInd(vo.getCbQ7FelonyInd());
		ret.setCbQ8NotOnListInd(vo.getCbQ8NotOnListInd());
		ret.setCbQ9ReputationInd(vo.getCbQ9ReputationInd());
		ret.setCbQ10InterPlanExecTxt(vo.getCbQ10InterPlanExecTxt());
		ret.setServiceCategoryBlueBenefit(vo.getServiceCategoryBlueBenefit());
		ret.setCbQ11OtherTxt(vo.getCbQ11OtherTxt());
		ret.setCbQ12TelehealthSvcInd(vo.getCbQ12TelehealthSvcInd());
		ret.setCbQ13VirtualOnlyInd(vo.getCbQ13VirtualOnlyInd());
		ret.setServiceCategoryNationalAccountMember(vo.getServiceCategoryNationalAccountMember());
		ret.setServiceCategoryServiceEntail(vo.getServiceCategoryServiceEntail());
		ret.setCbQ16ProviderOutreachInd(vo.getCbQ16ProviderOutreachInd());
		ret.setCbQ17ProviderOutreachTxt(vo.getCbQ17ProviderOutreachTxt());
		if (vo.getServiceCatQuestionsFlag() != null
				&& vo.getServiceCatQuestionsFlag().equalsIgnoreCase("Y")) {
			ret.setServiceCatQuestionsFlag("Y");
		}
		//Co-Branding Partner Form 17-question enhancement (save for later) end
		return ret;

	}

	public List<CoBrandBcbsaSupport> getCoBrandBcbsaSupportTypes() throws ServiceException {
		return coBrandBCBSASupportService.fetchAll();
	}
	
	public List<CoBrandBcbsaSupportVO> getCoBrandBcbsaSupportVoTypes() throws ServiceException {
		List<CoBrandBcbsaSupport> cobrandSupportTypes=coBrandBCBSASupportService.fetchAll();
		 List<CoBrandBcbsaSupportVO> cobrandSupportTypesVoList=new ArrayList<CoBrandBcbsaSupportVO>();
		 for(CoBrandBcbsaSupport support:cobrandSupportTypes){
			 CoBrandBcbsaSupportVO coBrandBcbsaSupportVO=new CoBrandBcbsaSupportVO();
			 coBrandBcbsaSupportVO.setCoBrandBcbsaSupportDesc(support.getCoBrandBcbsaSupportDesc());
			 coBrandBcbsaSupportVO.setcOBRANDBCBSASupportUID(support.getCOBRANDBCBSASupportUID());
			 cobrandSupportTypesVoList.add(coBrandBcbsaSupportVO);
		 }
		 return cobrandSupportTypesVoList;
	}
	
	public List<CoBrandBcbsaSupportVO> getCoBrandBcbsaSupportVoTypes(List<BrandRequestBcbsaSupport> bcbsaSupportList) throws ServiceException {
		List<CoBrandBcbsaSupport> cobrandSupportTypes=coBrandBCBSASupportService.fetchAll();
		Map<String,BrandRequestBcbsaSupport> brandRequestSupportMap=new HashMap<String,BrandRequestBcbsaSupport>();
		if(bcbsaSupportList!=null){
		for(BrandRequestBcbsaSupport support:bcbsaSupportList){
			brandRequestSupportMap.put(""+support.getCoBrandBcbsaSupport().getCOBRANDBCBSASupportUID(), support);
		}
		}
		
		List<CoBrandBcbsaSupportVO> cobrandSupportTypesVoList=new ArrayList<CoBrandBcbsaSupportVO>();
		 for(CoBrandBcbsaSupport support:cobrandSupportTypes){
			 CoBrandBcbsaSupportVO coBrandBcbsaSupportVO=new CoBrandBcbsaSupportVO();
			 coBrandBcbsaSupportVO.setCoBrandBcbsaSupportDesc(support.getCoBrandBcbsaSupportDesc());
			 coBrandBcbsaSupportVO.setcOBRANDBCBSASupportUID(support.getCOBRANDBCBSASupportUID());
			 if(brandRequestSupportMap.get(support.getCOBRANDBCBSASupportUID().toString())!=null){
				 coBrandBcbsaSupportVO.setSelected(true);
			 }
			 cobrandSupportTypesVoList.add(coBrandBcbsaSupportVO);
		 }
		 return cobrandSupportTypesVoList;
	}
	
	
	public List<CobrandRenewalType> getSelectedRenwalTypes(CobrandRenewalType cobrandRenewal) throws ServiceException {
		
			List<CobrandRenewalType> cobrandRenewalTypes=new ArrayList<CobrandRenewalType>();
			//Map<String,String> cobrandRenewalTypesMap=new HashMap<String,String>();
			List<CobrandReviewType> cobrandReviewTypes = cobrandReviewTypeService.getActiveCoBrandTypes("Y");
			Iterator<CobrandReviewType> it=cobrandReviewTypes.iterator();
			while(it.hasNext()){
				CobrandReviewType reviewType=it.next();
				if(reviewType.getCobrandRevwTypNm().equalsIgnoreCase("Select") ||
						reviewType.getCobrandRevwTypNm().equalsIgnoreCase("Premier") ||
						reviewType.getCobrandRevwTypNm().equalsIgnoreCase("Strategic")){
					CobrandRenewalType renwalType=new CobrandRenewalType();
					renwalType.setCobrandRevwTypNm(reviewType.getCobrandRevwTypNm()+"- Renewal");
					renwalType.setCobrandRenwTypUid(""+reviewType.getCobrandRevwTypUid());
					if(cobrandRenewal!=null && 
							reviewType.getCobrandRevwTypUid().toString().equals(cobrandRenewal.getCobrandRenwTypUid().toString())){
						renwalType.setSelected(true);
					}
					cobrandRenewalTypes.add(renwalType);
				//	cobrandRenewalTypesMap.put("renewal-"+reviewType.getCobrandRevwTypUid(), reviewType.getCobrandRevwTypNm());
				}
			}

		
		return cobrandRenewalTypes;
	}

	
	private String santizeInput(String input) throws Exception
	{
		if (input != null)
		{
			input = InputSanitizer.sanitize(input);
			//input = input.replaceAll("&quot;", "\"");
			//input = input.replaceAll("&amp;", "&");
			return input;
		}
		return input;
	}
	private String getUserDetails(String screenName) {
		UserDetailsVo vo = new UserDetailsVo();
		StringBuilder userFullDetails=new StringBuilder();
		long companyId=PortalUtil.getDefaultCompanyId();
		try {
			User user = UserLocalServiceUtil.getUserByScreenName(companyId, screenName);
			vo.setFullName(user.getFullName());
			vo.setEmailAddress(user.getEmailAddress());
			userFullDetails.append(user.getFullName()+" ("+user.getEmailAddress()+")");
		} catch (Exception e) {
			e.printStackTrace();
		}
		return userFullDetails.toString();
	}

}