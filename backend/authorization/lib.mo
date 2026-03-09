import Map "mo:core/Map";
import Models "../data/models";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";

module {

  // ── Store Type Aliases ────────────────────────────────────────────────────
  // Centralized here so all modules import one type definition.
  // Pattern: Map<tenantId, Map<entityId, Entity>>

  public type CustomerStore     = Map.Map<Nat, Map.Map<Nat, Models.Customer>>;
  public type SiteStore         = Map.Map<Nat, Map.Map<Nat, Models.Site>>;
  public type AssetTypeStore    = Map.Map<Nat, Map.Map<Nat, Models.AssetType>>;
  public type AssetStore        = Map.Map<Nat, Map.Map<Nat, Models.Asset>>;
  public type ZoneStore         = Map.Map<Nat, Map.Map<Nat, Models.Zone>>;
  public type PackStore         = Map.Map<Nat, Map.Map<Nat, Models.Pack>>;
  public type InspectionStore   = Map.Map<Nat, Map.Map<Nat, Models.Inspection>>;
  public type ReviewStore       = Map.Map<Nat, Map.Map<Nat, Models.InspectionReview>>;
  public type FindingStore      = Map.Map<Nat, Map.Map<Nat, Models.Finding>>;
  public type WorkOrderStore    = Map.Map<Nat, Map.Map<Nat, Models.WorkOrder>>;
  public type ScheduleStore     = Map.Map<Nat, Map.Map<Nat, Models.Schedule>>;
  public type NotificationStore = Map.Map<Nat, Map.Map<Nat, Models.Notification>>;
  public type AttachmentStore   = Map.Map<Nat, Map.Map<Nat, Models.Attachment>>;
  public type AuditStore        = Map.Map<Nat, Map.Map<Nat, Models.AuditLog>>;

  // ── Auth Context ──────────────────────────────────────────────────────────
  // Carried through every authenticated call.
  // Add fields here — not at call sites — when new context is needed.

  public type AuthContext = {
    userId    : Nat;
    tenantId  : Nat;
    role      : Models.Role;
    principal : Principal;
  };

  // ── Primary Auth Entry Point ──────────────────────────────────────────────
  // Call at the top of every shared method.
  // Returns AuthContext or error — never traps.

  public func requireAuth(
    users            : Map.Map<Nat, Models.User>,
    usersByPrincipal : Map.Map<Principal, Nat>,
    caller           : Principal,
  ) : { #ok : AuthContext; #err : Text } {
    switch (Map.get(usersByPrincipal, Principal.compare, caller)) {
      case null { #err "Unauthorized" };
      case (?userId) {
        switch (Map.get(users, Nat.compare, userId)) {
          case null    { #err "Unauthorized" };
          case (?user) {
            // isActive = false → suspended, can be reactivated
            // deletedAt != null → soft deleted, permanent
            if (not user.isActive)      { return #err "Unauthorized: account deactivated" };
            if (user.deletedAt != null) { return #err "Unauthorized: account deleted" };
            #ok {
              userId    = user.id;
              tenantId  = user.tenantId;
              role      = user.role;
              principal = caller;
            }
          };
        }
      };
    }
  };

  // ── Role Checks ───────────────────────────────────────────────────────────

  public func isPlatformAdmin(ctx : AuthContext) : Bool {
    ctx.role == #platformAdmin
  };

  public func isTenantAdmin(ctx : AuthContext) : Bool {
    ctx.role == #tenantAdmin or ctx.role == #platformAdmin
  };

  public func isCoordinatorOrAbove(ctx : AuthContext) : Bool {
    switch (ctx.role) {
      case (#platformAdmin or #tenantAdmin or #coordinator) { true };
      case _ { false };
    }
  };

  public func isFieldWorkerOrAbove(ctx : AuthContext) : Bool {
    switch (ctx.role) {
      case (#platformAdmin or #tenantAdmin or #coordinator or #fieldWorker) { true };
      case _ { false };
    }
  };

  public func isCustomerUser(ctx : AuthContext) : Bool {
    switch (ctx.role) {
      case (#customerAdmin or #customerInspector or #customerViewer) { true };
      case _ { false };
    }
  };

  // ── Cross-Tenant Access ───────────────────────────────────────────────────
  // Same-tenant methods: use ctx.tenantId directly — no check needed.
  // Cross-tenant methods: call this explicitly.
  // _subjectTenantId intentionally unused until grant/delegation logic added.

  public func requireCrossTenantAccess(
    ctx              : AuthContext,
    _subjectTenantId : Nat,
  ) : { #ok : (); #err : Text } {
    if (ctx.role == #platformAdmin) { return #ok () };
    #err "Unauthorized: cross-tenant access denied"
  };

  // ── Customer Scoping ──────────────────────────────────────────────────────
  // Customer users (customerId = ?n) see only their customer's data.
  // SP employees (customerId = null) see all data in their tenant.
  // Returns ?Nat — null means no customer restriction applies.

  public func customerScope(
    user : Models.User,
  ) : ?Nat {
    switch (user.role) {
      case (#customerAdmin or #customerInspector or #customerViewer) {
        user.customerId
      };
      case _ { null };
    }
  };

  // ── Foreign Key Validation ────────────────────────────────────────────────
  // Call on every write path to prevent cross-tenant references.
  // Checks: exists + same tenant + not soft-deleted.
  // Returns generic "not found" for all failure cases — never reveals existence.

  public func validateRef<T>(
    entity       : ?T,
    tenantId     : Nat,
    name         : Text,
    getTenantId  : T -> Nat,
    getDeletedAt : T -> ?Int,
  ) : { #ok : T; #err : Text } {
    switch (entity) {
      case null { #err (name # " not found") };
      case (?e) {
        if (getTenantId(e) != tenantId)  { return #err (name # " not found") };
        if (getDeletedAt(e) != null)     { return #err (name # " not found") };
        #ok e
      };
    }
  };

  // ── Bucket Helpers ────────────────────────────────────────────────────────
  // getBucket         → read path, no side effects, returns ?bucket
  // getOrCreateBucket → write path only, creates bucket if missing

  public func getBucket<T>(
    outerMap : Map.Map<Nat, Map.Map<Nat, T>>,
    tenantId : Nat,
  ) : ?Map.Map<Nat, T> {
    Map.get(outerMap, Nat.compare, tenantId)
  };

  public func getOrCreateBucket<T>(
    outerMap : Map.Map<Nat, Map.Map<Nat, T>>,
    tenantId : Nat,
  ) : Map.Map<Nat, T> {
    switch (Map.get(outerMap, Nat.compare, tenantId)) {
      case (?bucket) { bucket };
      case null {
        let bucket : Map.Map<Nat, T> = Map.empty();
        Map.add(outerMap, Nat.compare, tenantId, bucket);
        bucket
      };
    }
  };

};