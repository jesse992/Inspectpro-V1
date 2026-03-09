import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createFinding(
    store        : Auth.FindingStore,
    inspections  : Auth.InspectionStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    inspectionId : Nat,
    assetId      : Nat,
    fieldId      : ?Text,
    title        : Text,
    description  : Text,
    severity     : Nat,
  ) : { #ok : Models.Finding; #err : Text } {
    if (title == "") { return #err "Title is required" };
    let inspBucket = switch (Auth.getBucket(inspections, ctx.tenantId)) {
      case null    { return #err "Inspection not found" };
      case (?b)    { b };
    };
    switch (Auth.validateRef(
      Map.get(inspBucket, Nat.compare, inspectionId),
      ctx.tenantId, "Inspection",
      func(s : Models.Inspection) : Nat { s.tenantId },
      func(s : Models.Inspection) : ?Int { s.deletedAt },
    )) {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    let now = Time.now();
    let finding : Models.Finding = {
      id           = nextId;
      tenantId     = ctx.tenantId;
      inspectionId = inspectionId;
      assetId      = assetId;
      fieldId      = fieldId;
      title        = title;
      description  = description;
      severity     = severity;
      status       = #open;
      assignedTo   = null;
      resolvedAt   = null;
      resolvedBy   = null;
      createdAt    = now;
      updatedAt    = now;
      deletedAt    = null;
      version      = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, finding.id, finding);
    #ok finding
  };

  public func getFinding(
    store : Auth.FindingStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Finding; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Finding not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Finding not found" };
          case (?f) {
            if (f.deletedAt != null) { return #err "Finding not found" };
            #ok f
          };
        }
      };
    }
  };

  public func listFindings(
    store        : Auth.FindingStore,
    ctx          : Auth.AuthContext,
    inspectionId : ?Nat,
    assetId      : ?Nat,
    status       : ?Models.FindingStatus,
  ) : [Models.Finding] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Finding>(0);
        for ((_, f) in Map.entries(bucket)) {
          if (f.deletedAt == null) {
            let inspMatch = switch (inspectionId) {
              case null   { true };
              case (?iid) { f.inspectionId == iid };
            };
            let assetMatch = switch (assetId) {
              case null   { true };
              case (?aid) { f.assetId == aid };
            };
            let statusMatch = switch (status) {
              case null  { true };
              case (?s)  { f.status == s };
            };
            if (inspMatch and assetMatch and statusMatch) { result.add(f) };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func updateFindingStatus(
    store      : Auth.FindingStore,
    ctx        : Auth.AuthContext,
    id         : Nat,
    status     : Models.FindingStatus,
    assignedTo : ?Nat,
  ) : { #ok : Models.Finding; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Finding not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Finding not found" };
          case (?f) {
            if (f.deletedAt != null) { return #err "Finding not found" };
            let now = Time.now();
            let resolvedAt = switch (status) {
              case (#resolved or #closed) { ?now };
              case _                      { f.resolvedAt };
            };
            let resolvedBy = switch (status) {
              case (#resolved or #closed) { assignedTo };
              case _                      { f.resolvedBy };
            };
            let updated : Models.Finding = {
              id           = f.id;
              tenantId     = f.tenantId;
              inspectionId = f.inspectionId;
              assetId      = f.assetId;
              fieldId      = f.fieldId;
              title        = f.title;
              description  = f.description;
              severity     = f.severity;
              status       = status;
              assignedTo   = assignedTo;
              resolvedAt   = resolvedAt;
              resolvedBy   = resolvedBy;
              createdAt    = f.createdAt;
              updatedAt    = now;
              deletedAt    = f.deletedAt;
              version      = f.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteFinding(
    store : Auth.FindingStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Finding; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Finding not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Finding not found" };
          case (?f) {
            if (f.deletedAt != null) { return #err "Finding not found" };
            let now = Time.now();
            let updated : Models.Finding = {
              id           = f.id;
              tenantId     = f.tenantId;
              inspectionId = f.inspectionId;
              assetId      = f.assetId;
              fieldId      = f.fieldId;
              title        = f.title;
              description  = f.description;
              severity     = f.severity;
              status       = f.status;
              assignedTo   = f.assignedTo;
              resolvedAt   = f.resolvedAt;
              resolvedBy   = f.resolvedBy;
              createdAt    = f.createdAt;
              updatedAt    = now;
              deletedAt    = ?now;
              version      = f.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};