import Map "mo:core/Map";
import Models "data/models";
import Auth "authorization/lib";
import Tenants "logic/tenants";
import Users "logic/users";
import Invites "logic/invites";
import Customers "logic/customers";
import Sites "logic/sites";
import Assets "logic/assets";
import Zones "logic/zones";
import Packs "logic/packs";
import Inspections "logic/inspections";
import Reviews "logic/reviews";
import Findings "logic/findings";
import WorkOrders "logic/workorders";
import Schedules "logic/schedules";
import Notifications "logic/notifications";
import Attachments "logic/attachments";
import Audit "logic/audit";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import Time "mo:core/Time";

persistent actor InspectPro {

  // ── ID Counter ────────────────────────────────────────────────────────────

  var nextId : Nat = 1;

  private func newId() : Nat {
    let id = nextId;
    nextId += 1;
    id
  };

  // ── Storage ───────────────────────────────────────────────────────────────

  let tenants          : Map.Map<Nat, Models.Tenant>     = Map.empty();
  let users            : Map.Map<Nat, Models.User>       = Map.empty();
  let usersByPrincipal : Map.Map<Principal, Nat>         = Map.empty();
  let invites          : Map.Map<Nat, Models.InviteCode> = Map.empty();
  let invitesByCode    : Map.Map<Text, Nat>              = Map.empty();

  let customers     : Auth.CustomerStore     = Map.empty();
  let sites         : Auth.SiteStore         = Map.empty();
  let assetTypes    : Auth.AssetTypeStore    = Map.empty();
  let assets        : Auth.AssetStore        = Map.empty();
  let zones         : Auth.ZoneStore         = Map.empty();
  let packs         : Auth.PackStore         = Map.empty();
  let inspections   : Auth.InspectionStore   = Map.empty();
  let reviews       : Auth.ReviewStore       = Map.empty();
  let findings      : Auth.FindingStore      = Map.empty();
  let workOrders    : Auth.WorkOrderStore    = Map.empty();
  let schedules     : Auth.ScheduleStore     = Map.empty();
  let notifications : Auth.NotificationStore = Map.empty();
  let attachments   : Auth.AttachmentStore   = Map.empty();
  let auditLogs     : Auth.AuditStore        = Map.empty();

  var bootstrapped : Bool = false;

  // ── Auth Helper ───────────────────────────────────────────────────────────

  private func auth(caller : Principal) : { #ok : Auth.AuthContext; #err : Text } {
    Auth.requireAuth(users, usersByPrincipal, caller)
  };

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  public shared (msg) func bootstrap(
    tenantName : Text,
    adminName  : Text,
  ) : async { #ok : Text; #err : Text } {
    if (bootstrapped) return #err "Already bootstrapped";
    let tenant = Tenants.createTenant(tenants, newId(), tenantName, #serviceProvider);
    let userResult = Users.createUser(
  users, usersByPrincipal, newId(),
  tenant.id, msg.caller, #tenantAdmin,
  null, adminName, null, null,
  );
    switch userResult {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    bootstrapped := true;
    #ok ("Bootstrapped: " # tenant.name # " / " # adminName)
  };

  // ── Tenant Methods ────────────────────────────────────────────────────────

  public query func hasTenants() : async Bool { bootstrapped };

  public query func getTenant(id : Nat) : async { #ok : Models.Tenant; #err : Text } {
    Tenants.getTenant(tenants, id)
  };

  public query func listTenants() : async [Models.Tenant] {
    Tenants.listTenants(tenants)
  };

  public shared func updateTenant(
    id     : Nat,
    name   : Text,
    status : Models.TenantStatus,
  ) : async { #ok : Models.Tenant; #err : Text } {
    Tenants.updateTenant(tenants, id, name, status)
  };

  // ── User Methods ──────────────────────────────────────────────────────────

  public shared (msg) func createUser(
    tenantId   : Nat,
    role       : Models.Role,
    customerId : ?Nat,
    name       : Text,
    email      : ?Text,
  ) : async { #ok : Models.User; #err : Text } {
    Users.createUser(users, usersByPrincipal, newId(), tenantId, msg.caller, role, customerId, name, email, null)
  };

  public query func getUser(id : Nat) : async { #ok : Models.User; #err : Text } {
    Users.getUser(users, id)
  };

  public query (msg) func getMe() : async { #ok : Models.User; #err : Text } {
    Users.getUserByPrincipal(users, usersByPrincipal, msg.caller)
  };

  public query func listUsers(tenantId : Nat) : async [Models.User] {
    Users.listUsers(users, tenantId)
  };

  public shared func updateUser(
    id    : Nat,
    name  : Text,
    email : ?Text,
    role  : Models.Role,
  ) : async { #ok : Models.User; #err : Text } {
    Users.updateUser(users, id, name, email, null, role)
  };

  public shared func deactivateUser(id : Nat) : async { #ok : Models.User; #err : Text } {
    Users.deactivateUser(users, id)
  };

  // ── Invite Methods ────────────────────────────────────────────────────────

  public shared (msg) func createInvite(
    tenantId   : Nat,
    role       : Models.Role,
    customerId : ?Nat,
    code       : Text,
    expiresAt  : ?Int,
  ) : async { #ok : Models.InviteCode; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Invites.createInvite(invites, invitesByCode, newId(), tenantId, ctx.userId, role, customerId, code, expiresAt)
  };

  public query func getInviteByCode(code : Text) : async { #ok : Models.InviteCode; #err : Text } {
    Invites.getInviteByCode(invites, invitesByCode, code)
  };

  public query func listInvites(tenantId : Nat) : async [Models.InviteCode] {
    Invites.listInvites(invites, tenantId)
  };

  public shared func redeemInvite(
    code   : Text,
    usedBy : Nat,
  ) : async { #ok : Models.InviteCode; #err : Text } {
    Invites.redeemInvite(invites, invitesByCode, code, usedBy)
  };

  public shared func cancelInvite(id : Nat) : async { #ok : Models.InviteCode; #err : Text } {
    Invites.cancelInvite(invites, id)
  };

  // ── Customer Methods ──────────────────────────────────────────────────────

  public shared (msg) func createCustomer(
    name         : Text,
    contactName  : ?Text,
    contactEmail : ?Text,
    contactPhone : ?Text,
    address      : ?Text,
  ) : async { #ok : Models.Customer; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Customers.createCustomer(customers, newId(), ctx, name, contactName, contactEmail, contactPhone, address)
  };

  public shared (msg) func getCustomer(id : Nat) : async { #ok : Models.Customer; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Customers.getCustomer(customers, ctx, id)
  };

  public shared (msg) func listCustomers() : async { #ok : [Models.Customer]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Customers.listCustomers(customers, ctx))
  };

  public shared (msg) func updateCustomer(
    id           : Nat,
    name         : Text,
    contactName  : ?Text,
    contactEmail : ?Text,
    contactPhone : ?Text,
    address      : ?Text,
  ) : async { #ok : Models.Customer; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Customers.updateCustomer(customers, ctx, id, name, contactName, contactEmail, contactPhone, address)
  };

  public shared (msg) func deleteCustomer(id : Nat) : async { #ok : Models.Customer; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    Customers.deleteCustomer(customers, ctx, id)
  };

  // ── Site Methods ──────────────────────────────────────────────────────────

  public shared (msg) func createSite(
    customerId : Nat,
    name       : Text,
    address    : ?Text,
    latitude   : ?Float,
    longitude  : ?Float,
  ) : async { #ok : Models.Site; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Sites.createSite(sites, customers, newId(), ctx, name, address, customerId)
  };

  public shared (msg) func getSite(id : Nat) : async { #ok : Models.Site; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Sites.getSite(sites, ctx, id)
  };

  public shared (msg) func listSites(customerId : ?Nat) : async { #ok : [Models.Site]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Sites.listSites(sites, ctx, customerId))
  };

  public shared (msg) func updateSite(
    id        : Nat,
    name      : Text,
    address   : ?Text,
    latitude  : ?Float,
    longitude : ?Float,
  ) : async { #ok : Models.Site; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Sites.updateSite(sites, ctx, id, name, address)
  };

  public shared (msg) func deleteSite(id : Nat) : async { #ok : Models.Site; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    Sites.deleteSite(sites, ctx, id)
  };

  // ── AssetType Methods ─────────────────────────────────────────────────────

  public shared (msg) func createAssetType(
    name        : Text,
    description : ?Text,
    familyId    : ?Text,
  ) : async { #ok : Models.AssetType; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Assets.createAssetType(assetTypes, newId(), ctx, name, description, familyId)
  };

  public shared (msg) func getAssetType(id : Nat) : async { #ok : Models.AssetType; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Assets.getAssetType(assetTypes, ctx, id)
  };

  public shared (msg) func listAssetTypes() : async { #ok : [Models.AssetType]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Assets.listAssetTypes(assetTypes, ctx))
  };

  public shared (msg) func updateAssetType(
    id          : Nat,
    name        : Text,
    description : ?Text,
  ) : async { #ok : Models.AssetType; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Assets.updateAssetType(assetTypes, ctx, id, name, description)
  };

  public shared (msg) func deleteAssetType(id : Nat) : async { #ok : Models.AssetType; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    Assets.deleteAssetType(assetTypes, ctx, id)
  };

  // ── Asset Methods ─────────────────────────────────────────────────────────

  public shared (msg) func createAsset(
    customerId   : Nat,
    siteId       : Nat,
    zoneId       : ?Nat,
    assetTypeId  : Nat,
    name         : Text,
    serialNumber : ?Text,
    installedAt  : ?Int,
  ) : async { #ok : Models.Asset; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Assets.createAsset(assets, sites, assetTypes, newId(), ctx, customerId, siteId, zoneId, assetTypeId, name, serialNumber, installedAt)
  };

  public shared (msg) func getAsset(id : Nat) : async { #ok : Models.Asset; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Assets.getAsset(assets, ctx, id)
  };

  public shared (msg) func listAssets(
    siteId     : ?Nat,
    customerId : ?Nat,
  ) : async { #ok : [Models.Asset]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Assets.listAssets(assets, ctx, siteId, customerId))
  };

  public shared (msg) func updateAsset(
    id           : Nat,
    name         : Text,
    serialNumber : ?Text,
    zoneId       : ?Nat,
    assetTypeId  : Nat,
    installedAt  : ?Int,
  ) : async { #ok : Models.Asset; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Assets.updateAsset(assets, ctx, id, name, serialNumber, zoneId, assetTypeId, installedAt)
  };

  public shared (msg) func updateAssetStatus(
    id     : Nat,
    status : Models.AssetStatus,
  ) : async { #ok : Models.Asset; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Assets.updateAssetStatus(assets, ctx, id, status)
  };

  public shared (msg) func deleteAsset(id : Nat) : async { #ok : Models.Asset; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    Assets.deleteAsset(assets, ctx, id)
  };

  // ── Zone Methods ──────────────────────────────────────────────────────────

  public shared (msg) func createZone(
    siteId      : Nat,
    name        : Text,
    description : ?Text,
  ) : async { #ok : Models.Zone; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Zones.createZone(zones, sites, newId(), ctx, siteId, name, description)
  };

  public shared (msg) func getZone(id : Nat) : async { #ok : Models.Zone; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Zones.getZone(zones, ctx, id)
  };

  public shared (msg) func listZones(siteId : ?Nat) : async { #ok : [Models.Zone]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Zones.listZones(zones, ctx, siteId))
  };

  public shared (msg) func updateZone(
    id          : Nat,
    name        : Text,
    description : ?Text,
  ) : async { #ok : Models.Zone; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Zones.updateZone(zones, ctx, id, name, description)
  };

  public shared (msg) func deleteZone(id : Nat) : async { #ok : Models.Zone; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    Zones.deleteZone(zones, ctx, id)
  };

  // ── Pack Methods ──────────────────────────────────────────────────────────

  public shared (msg) func createPack(
    name         : Text,
    description  : ?Text,
    assetTypeId  : ?Nat,
    fields       : [Models.PackField],
    passMax      : ?Nat,
    attentionMax : ?Nat,
  ) : async { #ok : Models.Pack; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Packs.createPack(packs, newId(), ctx, name, description, assetTypeId, fields, passMax, attentionMax)
  };

  public shared (msg) func getPack(id : Nat) : async { #ok : Models.Pack; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Packs.getPack(packs, ctx, id)
  };

  public shared (msg) func listPacks(assetTypeId : ?Nat) : async { #ok : [Models.Pack]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Packs.listPacks(packs, ctx, assetTypeId))
  };

  public shared (msg) func updatePackMetadata(
    id          : Nat,
    name        : Text,
    description : ?Text,
    isActive    : Bool,
  ) : async { #ok : Models.Pack; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Packs.updatePackMetadata(packs, ctx, id, name, description, isActive)
  };

  public shared (msg) func updatePackSchema(
    id           : Nat,
    fields       : [Models.PackField],
    passMax      : ?Nat,
    attentionMax : ?Nat,
  ) : async { #ok : Models.Pack; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Packs.updatePackSchema(packs, newId(), ctx, id, fields, passMax, attentionMax)
  };

  public shared (msg) func deletePack(id : Nat) : async { #ok : Models.Pack; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    Packs.deletePack(packs, ctx, id)
  };

  // ── Inspection Methods ────────────────────────────────────────────────────

  public shared (msg) func createInspection(
    assetId     : Nat,
    customerId  : ?Nat,
    packId      : Nat,
    packVersion : Nat,
    scheduledAt : ?Int,
  ) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isFieldWorkerOrAbove(ctx)) { return #err "Unauthorized" };
    Inspections.createInspection(inspections, assets, packs, newId(), ctx, assetId, customerId, packId, packVersion, scheduledAt)
  };

  public shared (msg) func getInspection(id : Nat) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Inspections.getInspection(inspections, ctx, id)
  };

  public shared (msg) func listInspections(
    assetId : ?Nat,
    status  : ?Models.InspectionStatus,
  ) : async { #ok : [Models.Inspection]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Inspections.listInspections(inspections, ctx, assetId, status))
  };

  public shared (msg) func listMyInspections() : async { #ok : [Models.Inspection]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Inspections.listInspectionsByUser(inspections, ctx, ctx.userId))
  };

  public shared (msg) func assignInspection(
    id          : Nat,
    assignedTo  : Nat,
    scheduledAt : ?Int,
  ) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Inspections.assignInspection(inspections, ctx, id, assignedTo, scheduledAt)
  };

  public shared (msg) func startInspection(id : Nat) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Inspections.startInspection(inspections, ctx, id)
  };

  public shared (msg) func updateResponses(
    id        : Nat,
    responses : [Models.InspectionResponse],
  ) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Inspections.updateResponses(inspections, ctx, id, responses)
  };

  public shared (msg) func completeInspection(
    id        : Nat,
    responses : [Models.InspectionResponse],
  ) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Inspections.completeInspection(inspections, ctx, id, responses)
  };

  public shared (msg) func submitInspection(id : Nat) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Inspections.submitInspection(inspections, ctx, id)
  };

  public shared (msg) func deleteInspection(id : Nat) : async { #ok : Models.Inspection; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Inspections.deleteInspection(inspections, ctx, id)
  };

  // ── Review Methods ────────────────────────────────────────────────────────

  public shared (msg) func createReview(
    inspectionId : Nat,
    decision     : Models.ReviewDecision,
    notes        : ?Text,
  ) : async { #ok : Models.InspectionReview; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Reviews.createReview(reviews, inspections, newId(), ctx, inspectionId, decision, notes)
  };

  public shared (msg) func getReview(id : Nat) : async { #ok : Models.InspectionReview; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Reviews.getReview(reviews, ctx, id)
  };

  public shared (msg) func listReviewsByInspection(
    inspectionId : Nat,
  ) : async { #ok : [Models.InspectionReview]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Reviews.listReviewsByInspection(reviews, ctx, inspectionId))
  };

  // ── Finding Methods ───────────────────────────────────────────────────────

  public shared (msg) func createFinding(
    inspectionId : Nat,
    assetId      : Nat,
    fieldId      : ?Text,
    title        : Text,
    description  : Text,
    severity     : Nat,
  ) : async { #ok : Models.Finding; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isFieldWorkerOrAbove(ctx)) { return #err "Unauthorized" };
    Findings.createFinding(findings, inspections, newId(), ctx, inspectionId, assetId, fieldId, title, description, severity)
  };

  public shared (msg) func getFinding(id : Nat) : async { #ok : Models.Finding; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Findings.getFinding(findings, ctx, id)
  };

  public shared (msg) func listFindings(
    inspectionId : ?Nat,
    assetId      : ?Nat,
    status       : ?Models.FindingStatus,
  ) : async { #ok : [Models.Finding]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Findings.listFindings(findings, ctx, inspectionId, assetId, status))
  };

  public shared (msg) func updateFindingStatus(
    id         : Nat,
    status     : Models.FindingStatus,
    assignedTo : ?Nat,
  ) : async { #ok : Models.Finding; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Findings.updateFindingStatus(findings, ctx, id, status, assignedTo)
  };

  public shared (msg) func deleteFinding(id : Nat) : async { #ok : Models.Finding; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Findings.deleteFinding(findings, ctx, id)
  };

  // ── Work Order Methods ────────────────────────────────────────────────────

  public shared (msg) func createWorkOrder(
    assetId     : Nat,
    customerId  : ?Nat,
    findingIds  : [Nat],
    title       : Text,
    description : ?Text,
    dueAt       : ?Int,
  ) : async { #ok : Models.WorkOrder; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    WorkOrders.createWorkOrder(workOrders, assets, newId(), ctx, assetId, customerId, findingIds, title, description, dueAt)
  };

  public shared (msg) func getWorkOrder(id : Nat) : async { #ok : Models.WorkOrder; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    WorkOrders.getWorkOrder(workOrders, ctx, id)
  };

  public shared (msg) func listWorkOrders(
    assetId    : ?Nat,
    customerId : ?Nat,
    status     : ?Models.WorkOrderStatus,
  ) : async { #ok : [Models.WorkOrder]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (WorkOrders.listWorkOrders(workOrders, ctx, assetId, customerId, status))
  };

  public shared (msg) func assignWorkOrder(
    id         : Nat,
    assignedTo : Nat,
  ) : async { #ok : Models.WorkOrder; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    WorkOrders.assignWorkOrder(workOrders, ctx, id, assignedTo)
  };

  public shared (msg) func updateWorkOrderStatus(
    id     : Nat,
    status : Models.WorkOrderStatus,
  ) : async { #ok : Models.WorkOrder; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    WorkOrders.updateWorkOrderStatus(workOrders, ctx, id, status)
  };

  public shared (msg) func deleteWorkOrder(id : Nat) : async { #ok : Models.WorkOrder; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isTenantAdmin(ctx)) { return #err "Unauthorized" };
    WorkOrders.deleteWorkOrder(workOrders, ctx, id)
  };

  // ── Schedule Methods ──────────────────────────────────────────────────────

  public shared (msg) func createSchedule(
    assetId      : Nat,
    packId       : Nat,
    frequency    : Models.ScheduleFrequency,
    intervalDays : ?Nat,
    nextRunAt    : Int,
  ) : async { #ok : Models.Schedule; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Schedules.createSchedule(schedules, assets, packs, newId(), ctx, assetId, packId, frequency, intervalDays, nextRunAt)
  };

  public shared (msg) func getSchedule(id : Nat) : async { #ok : Models.Schedule; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Schedules.getSchedule(schedules, ctx, id)
  };

  public shared (msg) func listSchedules(assetId : ?Nat) : async { #ok : [Models.Schedule]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Schedules.listSchedules(schedules, ctx, assetId))
  };

  public shared (msg) func getDueSchedules() : async { #ok : [Models.Schedule]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Schedules.getDueSchedules(schedules, ctx, Time.now()))
  };

  public shared (msg) func pauseSchedule(id : Nat) : async { #ok : Models.Schedule; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Schedules.pauseSchedule(schedules, ctx, id)
  };

  public shared (msg) func resumeSchedule(id : Nat) : async { #ok : Models.Schedule; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Schedules.resumeSchedule(schedules, ctx, id)
  };

  public shared (msg) func markScheduleRan(
    id        : Nat,
    nextRunAt : Int,
  ) : async { #ok : Models.Schedule; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Schedules.markRan(schedules, ctx, id, nextRunAt)
  };

  public shared (msg) func deleteSchedule(id : Nat) : async { #ok : Models.Schedule; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    Schedules.deleteSchedule(schedules, ctx, id)
  };

  // ── Notification Methods ──────────────────────────────────────────────────

  public shared (msg) func createNotification(
    userId     : Nat,
    notifType  : Models.NotificationType,
    message    : Text,
    entityType : ?Text,
    entityId   : ?Nat,
  ) : async { #ok : Models.Notification; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Notifications.createNotification(notifications, newId(), ctx, userId, notifType, message, entityType, entityId)
  };

  public shared (msg) func listNotifications(unread : Bool) : async { #ok : [Models.Notification]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Notifications.listForUser(notifications, ctx, ctx.userId, unread))
  };

  public shared (msg) func markNotificationRead(id : Nat) : async { #ok : Models.Notification; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Notifications.markRead(notifications, ctx, id)
  };

  public shared (msg) func markAllNotificationsRead() : async { #ok : Nat; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Notifications.markAllRead(notifications, ctx, ctx.userId))
  };

  public shared (msg) func deleteNotification(id : Nat) : async { #ok : Models.Notification; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Notifications.deleteNotification(notifications, ctx, id)
  };

  // ── Attachment Methods ────────────────────────────────────────────────────

  public shared (msg) func createAttachment(
    entityType : Models.AttachmentEntityType,
    entityId   : Nat,
    fileName   : Text,
    mimeType   : ?Text,
    storageUrl : Text,
    sizeBytes  : ?Nat,
  ) : async { #ok : Models.Attachment; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Attachments.createAttachment(attachments, newId(), ctx, entityType, entityId, fileName, mimeType, storageUrl, sizeBytes)
  };

  public shared (msg) func getAttachment(id : Nat) : async { #ok : Models.Attachment; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Attachments.getAttachment(attachments, ctx, id)
  };

  public shared (msg) func listAttachmentsByEntity(entityId : Nat) : async { #ok : [Models.Attachment]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    #ok (Attachments.listAttachmentsByEntity(attachments, ctx, entityId))
  };

  public shared (msg) func deleteAttachment(id : Nat) : async { #ok : Models.Attachment; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    Attachments.deleteAttachment(attachments, ctx, id)
  };

  // ── Audit Log Methods ─────────────────────────────────────────────────────

  public shared (msg) func createLog(
    action     : Models.AuditAction,
    entityType : Text,
    entityId   : Nat,
    detail     : Text,
  ) : async Models.AuditLog {
    let ctx = switch (auth(msg.caller)) {
      case (#err _) {
        return {
          id = 0; tenantId = 0; userId = 0;
          action = action; entityType = entityType; entityId = entityId;
          detail = detail; createdAt = Time.now(); updatedAt = Time.now();
          deletedAt = null; version = 1;
        }
      };
      case (#ok c) { c };
    };
    Audit.createLog(auditLogs, newId(), ctx, action, entityType, entityId, detail)
  };

  public shared (msg) func listLogs(
    entityType : ?Text,
    entityId   : ?Nat,
    userId     : ?Nat,
  ) : async { #ok : [Models.AuditLog]; #err : Text } {
    let ctx = switch (auth(msg.caller)) {
      case (#err e) { return #err e };
      case (#ok c)  { c };
    };
    if (not Auth.isCoordinatorOrAbove(ctx)) { return #err "Unauthorized" };
    #ok (Audit.listLogs(auditLogs, ctx, entityType, entityId, userId))
  };

};