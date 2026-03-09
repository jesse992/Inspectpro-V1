import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";

module {

  private func calculateScore(responses : [Models.InspectionResponse]) : Nat {
    var flagged = 0;
    for (r in responses.vals()) {
      if (r.flagged) { flagged += 1 };
    };
    flagged
  };

  // ── Create ────────────────────────────────────────────────────────────────

  public func createInspection(
    store       : Auth.InspectionStore,
    assets      : Auth.AssetStore,
    packs       : Auth.PackStore,
    nextId      : Nat,
    ctx         : Auth.AuthContext,
    assetId     : Nat,
    customerId  : ?Nat,
    packId      : Nat,
    packVersion : Nat,
    scheduledAt : ?Int,
  ) : { #ok : Models.Inspection; #err : Text } {
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
    let packBucket = switch (Auth.getBucket(packs, ctx.tenantId)) {
      case null    { return #err "Pack not found" };
      case (?b)    { b };
    };
    switch (Auth.validateRef(
      Map.get(packBucket, Nat.compare, packId),
      ctx.tenantId, "Pack",
      func(s : Models.Pack) : Nat { s.tenantId },
      func(s : Models.Pack) : ?Int { s.deletedAt },
    )) {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    let now = Time.now();
    let inspection : Models.Inspection = {
      id          = nextId;
      tenantId    = ctx.tenantId;
      assetId     = assetId;
      customerId  = customerId;
      packId      = packId;
      packVersion = packVersion;
      assignedTo  = null;
      status      = #draft;
      responses   = [];
      score       = null;
      condition   = null;
      notes       = null;
      signature   = null;
      dueDate     = null;
      capturedLat = null;
      capturedLon = null;
      scheduledAt = scheduledAt;
      startedAt   = null;
      completedAt = null;
      submittedAt = null;
      createdBy   = ctx.userId;
      createdAt   = now;
      updatedAt   = now;
      deletedAt   = null;
      version     = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, inspection.id, inspection);
    #ok inspection
  };

  // ── Read ──────────────────────────────────────────────────────────────────

  public func getInspection(
    store : Auth.InspectionStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            #ok i
          };
        }
      };
    }
  };

  public func listInspections(
    store   : Auth.InspectionStore,
    ctx     : Auth.AuthContext,
    assetId : ?Nat,
    status  : ?Models.InspectionStatus,
  ) : [Models.Inspection] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Inspection>(0);
        for ((_, i) in Map.entries(bucket)) {
          if (i.deletedAt == null) {
            let assetMatch = switch (assetId) {
              case null   { true };
              case (?aid) { i.assetId == aid };
            };
            let statusMatch = switch (status) {
              case null  { true };
              case (?s)  { i.status == s };
            };
            if (assetMatch and statusMatch) { result.add(i) };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func listInspectionsByUser(
    store  : Auth.InspectionStore,
    ctx    : Auth.AuthContext,
    userId : Nat,
  ) : [Models.Inspection] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Inspection>(0);
        for ((_, i) in Map.entries(bucket)) {
          if (i.deletedAt == null) {
            switch (i.assignedTo) {
              case (?uid) { if (uid == userId) { result.add(i) } };
              case null   {};
            };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  public func assignInspection(
    store       : Auth.InspectionStore,
    ctx         : Auth.AuthContext,
    id          : Nat,
    assignedTo  : Nat,
    scheduledAt : ?Int,
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            switch (i.status) {
              case (#draft or #scheduled) {};
              case _ { return #err "Can only assign draft or scheduled inspections" };
            };
            let updated : Models.Inspection = {
              id          = i.id;
              tenantId    = i.tenantId;
              assetId     = i.assetId;
              customerId  = i.customerId;
              packId      = i.packId;
              packVersion = i.packVersion;
              assignedTo  = ?assignedTo;
              status      = #scheduled;
              responses   = i.responses;
              score       = i.score;
              condition   = i.condition;
              notes       = i.notes;
              signature   = i.signature;
              dueDate     = i.dueDate;
              capturedLat = i.capturedLat;
              capturedLon = i.capturedLon;
              scheduledAt = scheduledAt;
              startedAt   = i.startedAt;
              completedAt = i.completedAt;
              submittedAt = i.submittedAt;
              createdBy   = i.createdBy;
              createdAt   = i.createdAt;
              updatedAt   = Time.now();
              deletedAt   = i.deletedAt;
              version     = i.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func startInspection(
    store : Auth.InspectionStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            switch (i.status) {
              case (#draft or #scheduled) {};
              case _ { return #err "Can only start draft or scheduled inspections" };
            };
            let now = Time.now();
            let updated : Models.Inspection = {
              id          = i.id;
              tenantId    = i.tenantId;
              assetId     = i.assetId;
              customerId  = i.customerId;
              packId      = i.packId;
              packVersion = i.packVersion;
              assignedTo  = i.assignedTo;
              status      = #inProgress;
              responses   = i.responses;
              score       = i.score;
              condition   = i.condition;
              notes       = i.notes;
              signature   = i.signature;
              dueDate     = i.dueDate;
              capturedLat = i.capturedLat;
              capturedLon = i.capturedLon;
              scheduledAt = i.scheduledAt;
              startedAt   = ?now;
              completedAt = i.completedAt;
              submittedAt = i.submittedAt;
              createdBy   = i.createdBy;
              createdAt   = i.createdAt;
              updatedAt   = now;
              deletedAt   = i.deletedAt;
              version     = i.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func updateResponses(
    store     : Auth.InspectionStore,
    ctx       : Auth.AuthContext,
    id        : Nat,
    responses : [Models.InspectionResponse],
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            switch (i.status) {
              case (#draft or #scheduled or #inProgress) {};
              case _ { return #err "Cannot update a completed inspection" };
            };
            let updated : Models.Inspection = {
              id          = i.id;
              tenantId    = i.tenantId;
              assetId     = i.assetId;
              customerId  = i.customerId;
              packId      = i.packId;
              packVersion = i.packVersion;
              assignedTo  = i.assignedTo;
              status      = i.status;
              responses   = responses;
              score       = i.score;
              condition   = i.condition;
              notes       = i.notes;
              signature   = i.signature;
              dueDate     = i.dueDate;
              capturedLat = i.capturedLat;
              capturedLon = i.capturedLon;
              scheduledAt = i.scheduledAt;
              startedAt   = i.startedAt;
              completedAt = i.completedAt;
              submittedAt = i.submittedAt;
              createdBy   = i.createdBy;
              createdAt   = i.createdAt;
              updatedAt   = Time.now();
              deletedAt   = i.deletedAt;
              version     = i.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func completeInspection(
    store     : Auth.InspectionStore,
    ctx       : Auth.AuthContext,
    id        : Nat,
    responses : [Models.InspectionResponse],
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            switch (i.status) {
              case (#draft or #scheduled or #inProgress) {};
              case _ { return #err "Cannot complete a completed or reviewed inspection" };
            };
            let score = calculateScore(responses);
            let now   = Time.now();
            let updated : Models.Inspection = {
              id          = i.id;
              tenantId    = i.tenantId;
              assetId     = i.assetId;
              customerId  = i.customerId;
              packId      = i.packId;
              packVersion = i.packVersion;
              assignedTo  = i.assignedTo;
              status      = #completed;
              responses   = responses;
              score       = ?score;
              condition   = i.condition;
              notes       = i.notes;
              signature   = i.signature;
              dueDate     = i.dueDate;
              capturedLat = i.capturedLat;
              capturedLon = i.capturedLon;
              scheduledAt = i.scheduledAt;
              startedAt   = i.startedAt;
              completedAt = ?now;
              submittedAt = i.submittedAt;
              createdBy   = i.createdBy;
              createdAt   = i.createdAt;
              updatedAt   = now;
              deletedAt   = i.deletedAt;
              version     = i.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func submitInspection(
    store : Auth.InspectionStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            switch (i.status) {
              case (#completed) {};
              case _ { return #err "Only completed inspections can be submitted" };
            };
            let now = Time.now();
            let updated : Models.Inspection = {
              id          = i.id;
              tenantId    = i.tenantId;
              assetId     = i.assetId;
              customerId  = i.customerId;
              packId      = i.packId;
              packVersion = i.packVersion;
              assignedTo  = i.assignedTo;
              status      = #submitted;
              responses   = i.responses;
              score       = i.score;
              condition   = i.condition;
              notes       = i.notes;
              signature   = i.signature;
              dueDate     = i.dueDate;
              capturedLat = i.capturedLat;
              capturedLon = i.capturedLon;
              scheduledAt = i.scheduledAt;
              startedAt   = i.startedAt;
              completedAt = i.completedAt;
              submittedAt = ?now;
              createdBy   = i.createdBy;
              createdAt   = i.createdAt;
              updatedAt   = now;
              deletedAt   = i.deletedAt;
              version     = i.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteInspection(
    store : Auth.InspectionStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Inspection; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Inspection not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Inspection not found" };
          case (?i) {
            if (i.deletedAt != null) { return #err "Inspection not found" };
            let now = Time.now();
            let updated : Models.Inspection = {
              id          = i.id;
              tenantId    = i.tenantId;
              assetId     = i.assetId;
              customerId  = i.customerId;
              packId      = i.packId;
              packVersion = i.packVersion;
              assignedTo  = i.assignedTo;
              status      = i.status;
              responses   = i.responses;
              score       = i.score;
              condition   = i.condition;
              notes       = i.notes;
              signature   = i.signature;
              dueDate     = i.dueDate;
              capturedLat = i.capturedLat;
              capturedLon = i.capturedLon;
              scheduledAt = i.scheduledAt;
              startedAt   = i.startedAt;
              completedAt = i.completedAt;
              submittedAt = i.submittedAt;
              createdBy   = i.createdBy;
              createdAt   = i.createdAt;
              updatedAt   = now;
              deletedAt   = ?now;
              version     = i.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};