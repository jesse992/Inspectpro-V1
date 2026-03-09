import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  // Immutable — no update or delete functions by design

  public func createLog(
    store      : Auth.AuditStore,
    nextId     : Nat,
    ctx        : Auth.AuthContext,
    action     : Models.AuditAction,
    entityType : Text,
    entityId   : Nat,
    detail     : Text,
  ) : Models.AuditLog {
    let now = Time.now();
    let log : Models.AuditLog = {
      id         = nextId;
      tenantId   = ctx.tenantId;
      userId     = ctx.userId;
      action     = action;
      entityType = entityType;
      entityId   = entityId;
      detail     = detail;
      createdAt  = now;
      updatedAt  = now;
      deletedAt  = null;
      version    = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, log.id, log);
    log
  };

  public func getLog(
    store : Auth.AuditStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.AuditLog; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Audit log not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Audit log not found" };
          case (?l)  { #ok l };
        }
      };
    }
  };

  public func listLogs(
    store      : Auth.AuditStore,
    ctx        : Auth.AuthContext,
    entityType : ?Text,
    entityId   : ?Nat,
    userId     : ?Nat,
  ) : [Models.AuditLog] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.AuditLog>(0);
        for ((_, l) in Map.entries(bucket)) {
          let entityTypeMatch = switch (entityType) {
            case null   { true };
            case (?et)  { l.entityType == et };
          };
          let entityIdMatch = switch (entityId) {
            case null   { true };
            case (?eid) { l.entityId == eid };
          };
          let userMatch = switch (userId) {
            case null   { true };
            case (?uid) { l.userId == uid };
          };
          if (entityTypeMatch and entityIdMatch and userMatch) { result.add(l) };
        };
        Buffer.toArray(result)
      };
    }
  };

};