import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createNotification(
    store      : Auth.NotificationStore,
    nextId     : Nat,
    ctx        : Auth.AuthContext,
    userId     : Nat,
    notifType  : Models.NotificationType,
    message    : Text,
    entityType : ?Text,
    entityId   : ?Nat,
  ) : { #ok : Models.Notification; #err : Text } {
    let now = Time.now();
    let notif : Models.Notification = {
      id         = nextId;
      tenantId   = ctx.tenantId;
      userId     = userId;
      notifType  = notifType;
      message    = message;
      entityType = entityType;
      entityId   = entityId;
      isRead     = false;
      createdAt  = now;
      updatedAt  = now;
      deletedAt  = null;
      version    = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, notif.id, notif);
    #ok notif
  };

  public func getNotification(
    store : Auth.NotificationStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Notification; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Notification not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Notification not found" };
          case (?n) {
            if (n.deletedAt != null) { return #err "Notification not found" };
            #ok n
          };
        }
      };
    }
  };

  public func listForUser(
    store  : Auth.NotificationStore,
    ctx    : Auth.AuthContext,
    userId : Nat,
    unread : Bool,
  ) : [Models.Notification] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Notification>(0);
        for ((_, n) in Map.entries(bucket)) {
          if (n.userId == userId and n.deletedAt == null) {
            if (unread and not n.isRead) { result.add(n) }
            else if (not unread)        { result.add(n) };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func markRead(
    store : Auth.NotificationStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Notification; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Notification not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Notification not found" };
          case (?n) {
            if (n.deletedAt != null) { return #err "Notification not found" };
            let updated : Models.Notification = {
              id         = n.id;
              tenantId   = n.tenantId;
              userId     = n.userId;
              notifType  = n.notifType;
              message    = n.message;
              entityType = n.entityType;
              entityId   = n.entityId;
              isRead     = true;
              createdAt  = n.createdAt;
              updatedAt  = Time.now();
              deletedAt  = n.deletedAt;
              version    = n.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func markAllRead(
    store  : Auth.NotificationStore,
    ctx    : Auth.AuthContext,
    userId : Nat,
  ) : Nat {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { 0 };
      case (?bucket) {
        var count = 0;
        let now = Time.now();
        for ((_, n) in Map.entries(bucket)) {
          if (n.userId == userId and not n.isRead and n.deletedAt == null) {
            let updated : Models.Notification = {
              id         = n.id;
              tenantId   = n.tenantId;
              userId     = n.userId;
              notifType  = n.notifType;
              message    = n.message;
              entityType = n.entityType;
              entityId   = n.entityId;
              isRead     = true;
              createdAt  = n.createdAt;
              updatedAt  = now;
              deletedAt  = n.deletedAt;
              version    = n.version + 1;
            };
            Map.add(bucket, Nat.compare, n.id, updated);
            count += 1;
          };
        };
        count
      };
    }
  };

  public func deleteNotification(
    store : Auth.NotificationStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Notification; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Notification not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Notification not found" };
          case (?n) {
            if (n.deletedAt != null) { return #err "Notification not found" };
            let now = Time.now();
            let updated : Models.Notification = {
              id         = n.id;
              tenantId   = n.tenantId;
              userId     = n.userId;
              notifType  = n.notifType;
              message    = n.message;
              entityType = n.entityType;
              entityId   = n.entityId;
              isRead     = n.isRead;
              createdAt  = n.createdAt;
              updatedAt  = now;
              deletedAt  = ?now;
              version    = n.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};