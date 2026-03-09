import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";

module {

  public func createSchedule(
    store        : Auth.ScheduleStore,
    assets       : Auth.AssetStore,
    packs        : Auth.PackStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    assetId      : Nat,
    packId       : Nat,
    frequency    : Models.ScheduleFrequency,
    intervalDays : ?Nat,
    nextRunAt    : Int,
  ) : { #ok : Models.Schedule; #err : Text } {
    let assetBucket = switch (Auth.getBucket(assets, ctx.tenantId)) {
      case null  { return #err "Asset not found" };
      case (?b)  { b };
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
      case null  { return #err "Pack not found" };
      case (?b)  { b };
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
    let schedule : Models.Schedule = {
      id           = nextId;
      tenantId     = ctx.tenantId;
      assetId      = assetId;
      packId       = packId;
      frequency    = frequency;
      intervalDays = intervalDays;
      nextRunAt    = nextRunAt;
      lastRunAt    = null;
      isActive     = true;
      createdBy    = ctx.userId;
      createdAt    = now;
      updatedAt    = now;
      deletedAt    = null;
      version      = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, schedule.id, schedule);
    #ok schedule
  };

  public func getSchedule(
    store : Auth.ScheduleStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Schedule; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Schedule not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Schedule not found" };
          case (?s)  {
            if (s.deletedAt != null) { return #err "Schedule not found" };
            #ok s
          };
        }
      };
    }
  };

  public func listSchedules(
    store   : Auth.ScheduleStore,
    ctx     : Auth.AuthContext,
    assetId : ?Nat,
  ) : [Models.Schedule] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Schedule>(0);
        for ((_, s) in Map.entries(bucket)) {
          if (s.deletedAt == null) {
            switch (assetId) {
              case null   { result.add(s) };
              case (?aid) { if (s.assetId == aid) { result.add(s) } };
            };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func getDueSchedules(
    store : Auth.ScheduleStore,
    ctx   : Auth.AuthContext,
    now   : Int,
  ) : [Models.Schedule] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Schedule>(0);
        for ((_, s) in Map.entries(bucket)) {
          if (s.deletedAt == null and s.isActive and s.nextRunAt <= now) {
            result.add(s)
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func pauseSchedule(
    store : Auth.ScheduleStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Schedule; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Schedule not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Schedule not found" };
          case (?s)  {
            if (s.deletedAt != null) { return #err "Schedule not found" };
            let updated : Models.Schedule = {
              id           = s.id;
              tenantId     = s.tenantId;
              assetId      = s.assetId;
              packId       = s.packId;
              frequency    = s.frequency;
              intervalDays = s.intervalDays;
              nextRunAt    = s.nextRunAt;
              lastRunAt    = s.lastRunAt;
              isActive     = false;
              createdBy    = s.createdBy;
              createdAt    = s.createdAt;
              updatedAt    = Time.now();
              deletedAt    = s.deletedAt;
              version      = s.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func resumeSchedule(
    store : Auth.ScheduleStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Schedule; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Schedule not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Schedule not found" };
          case (?s)  {
            if (s.deletedAt != null) { return #err "Schedule not found" };
            let updated : Models.Schedule = {
              id           = s.id;
              tenantId     = s.tenantId;
              assetId      = s.assetId;
              packId       = s.packId;
              frequency    = s.frequency;
              intervalDays = s.intervalDays;
              nextRunAt    = s.nextRunAt;
              lastRunAt    = s.lastRunAt;
              isActive     = true;
              createdBy    = s.createdBy;
              createdAt    = s.createdAt;
              updatedAt    = Time.now();
              deletedAt    = s.deletedAt;
              version      = s.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func markRan(
    store     : Auth.ScheduleStore,
    ctx       : Auth.AuthContext,
    id        : Nat,
    nextRunAt : Int,
  ) : { #ok : Models.Schedule; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Schedule not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Schedule not found" };
          case (?s)  {
            if (s.deletedAt != null) { return #err "Schedule not found" };
            let now = Time.now();
            let updated : Models.Schedule = {
              id           = s.id;
              tenantId     = s.tenantId;
              assetId      = s.assetId;
              packId       = s.packId;
              frequency    = s.frequency;
              intervalDays = s.intervalDays;
              nextRunAt    = nextRunAt;
              lastRunAt    = ?now;
              isActive     = s.isActive;
              createdBy    = s.createdBy;
              createdAt    = s.createdAt;
              updatedAt    = now;
              deletedAt    = s.deletedAt;
              version      = s.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteSchedule(
    store : Auth.ScheduleStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Schedule; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Schedule not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Schedule not found" };
          case (?s)  {
            if (s.deletedAt != null) { return #err "Schedule not found" };
            let now = Time.now();
            let updated : Models.Schedule = {
              id           = s.id;
              tenantId     = s.tenantId;
              assetId      = s.assetId;
              packId       = s.packId;
              frequency    = s.frequency;
              intervalDays = s.intervalDays;
              nextRunAt    = s.nextRunAt;
              lastRunAt    = s.lastRunAt;
              isActive     = false;
              createdBy    = s.createdBy;
              createdAt    = s.createdAt;
              updatedAt    = now;
              deletedAt    = ?now;
              version      = s.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};