module {

  // -------------------------------------------------------------------------
  // URL Type Alias
  // -------------------------------------------------------------------------

  public type Url = Text;

  // -------------------------------------------------------------------------
  // Enums / Variant Types
  // -------------------------------------------------------------------------

  public type TenantType = {
    #serviceProvider;
    #assetOwner;
  };

  public type TenantStatus = {
    #trial;
    #active;
    #suspended;
    #cancelled;
  };

  public type Role = {
    #platformAdmin;
    #tenantAdmin;
    #coordinator;
    #fieldWorker;
    #viewer;
    #customerAdmin;
    #customerInspector;
    #customerViewer;
  };

  public type AssetStatus = {
    #active;
    #inactive;
    #needsRepair;
    #retired;
  };

  public type InspectionStatus = {
    #draft;
    #scheduled;
    #inProgress;
    #completed;
    #submitted;
    #reviewed;
    #cancelled;
  };

  public type InspectionCondition = {
    #pass;
    #needsAttention;
    #fail;
  };

  public type ReviewDecision = {
    #approved;
    #rejected;
  };

  public type FindingStatus = {
    #open;
    #inProgress;
    #resolved;
    #closed;
  };

  public type WorkOrderStatus = {
    #open;
    #assigned;
    #inProgress;
    #completed;
    #cancelled;
  };

  public type ScheduleFrequency = {
    #once;
    #daily;
    #weekly;
    #monthly;
    #quarterly;
    #annually;
    #custom;
  };

  public type AuditAction = {
    #create;
    #update;
    #delete;
    #statusChange;
    #login;
  };

  public type NotificationType = {
    #inviteCreated;
    #inspectionAssigned;
    #inspectionSubmitted;
    #inspectionReviewed;
    #workOrderAssigned;
    #findingUpdated;
    #agreementExpiring;
    #scheduleTriggered;
  };

  public type ServiceAgreementType = {
    #oneTime;
    #monthly;
    #quarterly;
    #annual;
    #custom;
  };

  public type ServiceAgreementStatus = {
    #active;
    #expiring;
    #expired;
    #cancelled;
  };

  public type AttachmentEntityType = {
    #inspection;
    #finding;
    #workOrder;
    #asset;
    #comment;
  };

  public type CommentEntityType = {
    #inspection;
    #finding;
    #workOrder;
    #asset;
  };

  // -------------------------------------------------------------------------
  // Sub-records
  // -------------------------------------------------------------------------

  public type PackField = {
    id         : Text;
    fieldLabel : Text;
    fieldType  : Text;
    required   : Bool;
    options    : [Text];
    passValue  : ?Text;
    failValues : [Text];
    helpText   : ?Text;
    sortOrder  : Nat;
  };

  public type InspectionResponse = {
    fieldId : Text;
    value   : Text;
    flagged : Bool;
    note    : ?Text;
  };

  // -------------------------------------------------------------------------
  // Top-Level Entities
  // -------------------------------------------------------------------------

  public type Tenant = {
    id                          : Nat;
    name                        : Text;
    tenantType                  : TenantType;
    linkedTenantId              : ?Nat;
    status                      : TenantStatus;
    contactName                 : ?Text;
    contactEmail                : ?Text;
    contactPhone                : ?Text;
    address                     : ?Text;
    logoUrl                     : ?Url;
    websiteUrl                  : ?Url;
    timezone                    : ?Text;
    defaultPackId               : ?Nat;
    notifyOnInspectionComplete  : Bool;
    notifyOnInspectionFailed    : Bool;
    notifyDaysBeforeDue         : Nat;
    createdAt                   : Int;
    updatedAt                   : Int;
    deletedAt                   : ?Int;
    version                     : Nat;
  };

  public type User = {
    id                  : Nat;
    tenantId            : Nat;
    principal           : Principal;
    role                : Role;
    customerId          : ?Nat;
    name                : Text;
    email               : ?Text;
    phone               : ?Text;
    avatarUrl           : ?Url;
    isActive            : Bool;
    emailNotifications  : Bool;
    inAppNotifications  : Bool;
    theme               : Text;
    lastLoginAt         : ?Int;
    createdAt           : Int;
    updatedAt           : Int;
    deletedAt           : ?Int;
    version             : Nat;
  };

  public type InviteCode = {
    id         : Nat;
    tenantId   : Nat;
    code       : Text;
    role       : Role;
    customerId : ?Nat;
    createdBy  : Nat;
    expiresAt  : ?Int;
    usedBy     : ?Nat;
    usedAt     : ?Int;
    isActive   : Bool;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

  public type Customer = {
    id             : Nat;
    tenantId       : Nat;
    linkedTenantId : ?Nat; 
    name           : Text;
    contactName  : ?Text;
    contactEmail : ?Text;
    contactPhone : ?Text;
    address      : ?Text;
    logoUrl      : ?Url;
    isActive     : Bool;
    createdAt    : Int;
    updatedAt    : Int;
    deletedAt    : ?Int;
    version      : Nat;
  };

  public type Site = {
    id         : Nat;
    tenantId   : Nat;
    customerId : Nat;
    name       : Text;
    address    : ?Text;
    latitude   : ?Float;
    longitude  : ?Float;
    isActive   : Bool;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

  public type Zone = {
    id          : Nat;
    tenantId    : Nat;
    siteId      : Nat;
    name        : Text;
    description : ?Text;
    isActive    : Bool;
    createdAt   : Int;
    updatedAt   : Int;
    deletedAt   : ?Int;
    version     : Nat;
  };

  public type AssetType = {
    id          : Nat;
    tenantId    : Nat;
    name        : Text;
    description : ?Text;
    familyId    : ?Text;
    isActive    : Bool;
    createdAt   : Int;
    updatedAt   : Int;
    deletedAt   : ?Int;
    version     : Nat;
  };

  public type Asset = {
    id           : Nat;
    tenantId     : Nat;
    customerId   : Nat;
    siteId       : Nat;
    zoneId       : ?Nat;
    assetTypeId  : Nat;
    name         : Text;
    serialNumber : ?Text;
    status       : AssetStatus;
    installedAt  : ?Int;
    createdAt    : Int;
    updatedAt    : Int;
    deletedAt    : ?Int;
    version      : Nat;
  };

  public type Pack = {
    id              : Nat;
    tenantId        : Nat;
    name            : Text;
    description     : ?Text;
    assetTypeId     : ?Nat;
    fields          : [PackField];
    passMax         : ?Nat;
    attentionMax    : ?Nat;
    packVersion     : Nat;
    parentPackId    : ?Nat;
    createdBy       : Nat;
    isActive        : Bool;
    requiresCertification : Bool;
    requiresPhotos        : Bool;
    requiresSignature     : Bool;
    requiresGPS           : Bool;
    createdAt       : Int;
    updatedAt       : Int;
    deletedAt       : ?Int;
    version         : Nat;
  };

  public type Inspection = {
    id          : Nat;
    tenantId    : Nat;
    assetId     : Nat;
    customerId  : ?Nat;
    packId      : Nat;
    packVersion : Nat;
    assignedTo  : ?Nat;
    status      : InspectionStatus;
    responses   : [InspectionResponse];
    condition   : ?InspectionCondition;
    score       : ?Nat;
    notes       : ?Text;
    signature   : ?Text;
    capturedLat : ?Float;
    capturedLon : ?Float;
    dueDate     : ?Int;
    scheduledAt : ?Int;
    startedAt   : ?Int;
    completedAt : ?Int;
    submittedAt : ?Int;
    createdBy   : Nat;
    createdAt   : Int;
    updatedAt   : Int;
    deletedAt   : ?Int;
    version     : Nat;
  };

  public type InspectionReview = {
    id           : Nat;
    tenantId     : Nat;
    inspectionId : Nat;
    reviewedBy   : Nat;
    decision     : ReviewDecision;
    notes        : ?Text;
    createdAt    : Int;
    updatedAt    : Int;
    deletedAt    : ?Int;
    version      : Nat;
  };

  public type Finding = {
    id           : Nat;
    tenantId     : Nat;
    inspectionId : Nat;
    assetId      : Nat;
    fieldId      : ?Text;
    title        : Text;
    description  : Text;
    severity     : Nat;
    status       : FindingStatus;
    assignedTo   : ?Nat;
    resolvedAt   : ?Int;
    resolvedBy   : ?Nat;
    createdAt    : Int;
    updatedAt    : Int;
    deletedAt    : ?Int;
    version      : Nat;
  };

  public type WorkOrder = {
    id          : Nat;
    tenantId    : Nat;
    assetId     : Nat;
    customerId  : ?Nat;
    findingIds  : [Nat];
    title       : Text;
    description : ?Text;
    assignedTo  : ?Nat;
    status      : WorkOrderStatus;
    dueAt       : ?Int;
    completedAt : ?Int;
    createdBy   : Nat;
    createdAt   : Int;
    updatedAt   : Int;
    deletedAt   : ?Int;
    version     : Nat;
  };

  public type Schedule = {
    id           : Nat;
    tenantId     : Nat;
    assetId      : Nat;
    packId       : Nat;
    frequency    : ScheduleFrequency;
    intervalDays : ?Nat;
    nextRunAt    : Int;
    lastRunAt    : ?Int;
    createdBy    : Nat;
    isActive     : Bool;
    createdAt    : Int;
    updatedAt    : Int;
    deletedAt    : ?Int;
    version      : Nat;
  };

  public type PackFamilySubscription = {
    id           : Nat;
    tenantId     : Nat;
    packFamilyId : Text;
    isActive     : Bool;
    createdAt    : Int;
    updatedAt    : Int;
    deletedAt    : ?Int;
    version      : Nat;
  };

  public type ServiceAgreement = {
    id            : Nat;
    tenantId      : Nat;
    customerId    : Nat;
    title         : Text;
    agreementType : ServiceAgreementType;
    value         : ?Nat;
    content       : ?Text;
    startAt       : Int;
    endAt         : ?Int;
    status        : ServiceAgreementStatus;
    isActive      : Bool;
    createdAt     : Int;
    updatedAt     : Int;
    deletedAt     : ?Int;
    version       : Nat;
  };

  public type Notification = {
    id         : Nat;
    tenantId   : Nat;
    userId     : Nat;
    notifType  : NotificationType;
    message    : Text;
    entityType : ?Text;
    entityId   : ?Nat;
    isRead     : Bool;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

  public type AuditLog = {
    id         : Nat;
    tenantId   : Nat;
    userId     : Nat;
    action     : AuditAction;
    entityType : Text;
    entityId   : Nat;
    detail     : Text;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

  public type Attachment = {
    id         : Nat;
    tenantId   : Nat;
    entityType : AttachmentEntityType;
    entityId   : Nat;
    fileName   : Text;
    mimeType   : ?Text;
    storageUrl : Url;
    uploadedBy : Nat;
    sizeBytes  : ?Nat;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

  public type Tag = {
    id        : Nat;
    tenantId  : Nat;
    name      : Text;
    color     : ?Text;
    createdAt : Int;
    updatedAt : Int;
    deletedAt : ?Int;
    version   : Nat;
  };

  public type TagAssignment = {
    id         : Nat;
    tenantId   : Nat;
    tagId      : Nat;
    entityType : Text;
    entityId   : Nat;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

  public type Comment = {
    id         : Nat;
    tenantId   : Nat;
    entityType : CommentEntityType;
    entityId   : Nat;
    authorId   : Nat;
    body       : Text;
    createdAt  : Int;
    updatedAt  : Int;
    deletedAt  : ?Int;
    version    : Nat;
  };

}