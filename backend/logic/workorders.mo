import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createWorkOrder(
    store       : Auth.WorkOrderStore,
    assets      : Auth.AssetStore,
    nextId      : Nat,
    ctx         : Auth.AuthContext,
    assetId     : Nat,
    customerId  : ?Nat,
    findingIds  : [Nat],
    title       : Text,
    description : ?Text,
    dueAt       : ?Int,
  ) : { #ok : Models.WorkOrder; #err : Text } {
    if (title == "") { return #err "Title is required" };
    let assetBucket = switch (Auth.getBucket(assets, ctx.tenantId)) {
      case null    { return #err "Asset not found" };
      case (?b)    { b };
    };
    switch (Auth.validateRef(
      Map.get(assetBucket, Nat.compare, assetId),
      ctx.tenantId, "Asset",
      func(s : Models.Asset) : Nat { s.tenantId },
      func(s : Models.Asset) : ?Int { s.deletedAt },
    )) {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    let now = Time.now();
    let workOrder : Models.WorkOrder = {
      id          = nextId;
      tenantId    = ctx.tenantId;
      assetId     = assetId;
      customerId  = customerId;
      findingIds  = findingIds;
      title       = title;
      description = description;
      assignedTo  = null;
      status      = #open;
      dueAt       = dueAt;
      completedAt = null;
      createdBy   = ctx.userId;
      createdAt   = now;
      updatedAt   = now;
      deletedAt   = null;
      version     = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, workOrder.id, workOrder);
    #ok workOrder
  };

  public func getWorkOrder(
    store : Auth.WorkOrderStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.WorkOrder; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Work order not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Work order not found" };
          case (?w) {
            if (w.deletedAt != null) { return #err "Work order not found" };
            #ok w
          };
        }
      };
    }
  };

  public func listWorkOrders(
    store      : Auth.WorkOrderStore,
    ctx        : Auth.AuthContext,
    assetId    : ?Nat,
    customerId : ?Nat,
    status     : ?Models.WorkOrderStatus,
  ) : [Models.WorkOrder] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.WorkOrder>(0);
        for ((_, w) in Map.entries(bucket)) {
          if (w.deletedAt == null) {
            let assetMatch = switch (assetId) {
              case null   { true };
              case (?aid) { w.assetId == aid };
            };
            let customerMatch = switch (customerId) {
              case null   { true };
              case (?cid) {
                switch (w.customerId) {
                  case null      { false };
                  case (?wcid)   { wcid == cid };
                }
              };
            };
            let statusMatch = switch (status) {
              case null  { true };
              case (?s)  { w.status == s };
            };
            if (assetMatch and customerMatch and statusMatch) { result.add(w) };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func assignWorkOrder(
    store      : Auth.WorkOrderStore,
    ctx        : Auth.AuthContext,
    id         : Nat,
    assignedTo : Nat,
  ) : { #ok : Models.WorkOrder; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Work order not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Work order not found" };
          case (?w) {
            if (w.deletedAt != null) { return #err "Work order not found" };
            switch (w.status) {
              case (#completed or #cancelled) {
                return #err "Cannot assign a completed or cancelled work order"
              };
              case _ {};
            };
            let updated : Models.WorkOrder = {
              id          = w.id;
              tenantId    = w.tenantId;
              assetId     = w.assetId;
              customerId  = w.customerId;
              findingIds  = w.findingIds;
              title       = w.title;
              description = w.description;
              assignedTo  = ?assignedTo;
              status      = #assigned;
              dueAt       = w.dueAt;
              completedAt = w.completedAt;
              createdBy   = w.createdBy;
              createdAt   = w.createdAt;
              updatedAt   = Time.now();
              deletedAt   = w.deletedAt;
              version     = w.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func updateWorkOrderStatus(
    store  : Auth.WorkOrderStore,
    ctx    : Auth.AuthContext,
    id     : Nat,
    status : Models.WorkOrderStatus,
  ) : { #ok : Models.WorkOrder; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Work order not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Work order not found" };
          case (?w) {
            if (w.deletedAt != null) { return #err "Work order not found" };
            let now = Time.now();
            let completedAt = switch (status) {
              case (#completed) { ?now };
              case _            { w.completedAt };
            };
            let updated : Models.WorkOrder = {
              id          = w.id;
              tenantId    = w.tenantId;
              assetId     = w.assetId;
              customerId  = w.customerId;
              findingIds  = w.findingIds;
              title       = w.title;
              description = w.description;
              assignedTo  = w.assignedTo;
              status      = status;
              dueAt       = w.dueAt;
              completedAt = completedAt;
              createdBy   = w.createdBy;
              createdAt   = w.createdAt;
              updatedAt   = now;
              deletedAt   = w.deletedAt;
              version     = w.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteWorkOrder(
    store : Auth.WorkOrderStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.WorkOrder; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Work order not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Work order not found" };
          case (?w) {
            if (w.deletedAt != null) { return #err "Work order not found" };
            let now = Time.now();
            let updated : Models.WorkOrder = {
              id          = w.id;
              tenantId    = w.tenantId;
              assetId     = w.assetId;
              customerId  = w.customerId;
              findingIds  = w.findingIds;
              title       = w.title;
              description = w.description;
              assignedTo  = w.assignedTo;
              status      = w.status;
              dueAt       = w.dueAt;
              completedAt = w.completedAt;
              createdBy   = w.createdBy;
              createdAt   = w.createdAt;
              updatedAt   = now;
              deletedAt   = ?now;
              version     = w.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};