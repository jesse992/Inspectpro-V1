import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";

module {

  // Immutable — no update or delete functions by design

  public func createReview(
    store        : Auth.ReviewStore,
    inspections  : Auth.InspectionStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    inspectionId : Nat,
    decision     : Models.ReviewDecision,
    notes        : ?Text,
  ) : { #ok : Models.InspectionReview; #err : Text } {
    // Validate inspection exists, same tenant, and is submitted
    let inspBucket = switch (Auth.getBucket(inspections, ctx.tenantId)) {
      case null    { return #err "Inspection not found" };
      case (?b)    { b };
    };
    switch (Map.get(inspBucket, Nat.compare, inspectionId)) {
      case null    { return #err "Inspection not found" };
      case (?i) {
        if (i.tenantId != ctx.tenantId) { return #err "Inspection not found" };
        if (i.deletedAt != null)        { return #err "Inspection not found" };
        switch (i.status) {
          case (#submitted) {};
          case _ { return #err "Only submitted inspections can be reviewed" };
        };
      };
    };
    let now = Time.now();
    let review : Models.InspectionReview = {
      id           = nextId;
      tenantId     = ctx.tenantId;
      inspectionId = inspectionId;
      reviewedBy   = ctx.userId;
      decision     = decision;
      notes        = notes;
      createdAt    = now;
      updatedAt    = now;
      deletedAt    = null;
      version      = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, review.id, review);
    #ok review
  };

  public func getReview(
    store : Auth.ReviewStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.InspectionReview; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Review not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Review not found" };
          case (?r)  { #ok r };
        }
      };
    }
  };

  public func listReviewsByInspection(
    store        : Auth.ReviewStore,
    ctx          : Auth.AuthContext,
    inspectionId : Nat,
  ) : [Models.InspectionReview] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.InspectionReview>(0);
        for ((_, r) in Map.entries(bucket)) {
          if (r.inspectionId == inspectionId) { result.add(r) };
        };
        Buffer.toArray(result)
      };
    }
  };

};