import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createZone(
    store       : Auth.ZoneStore,
    sites       : Auth.SiteStore,
    nextId      : Nat,
    ctx         : Auth.AuthContext,
    siteId      : Nat,
    name        : Text,
    description : ?Text,
  ) : { #ok : Models.Zone; #err : Text } {
    if (name == "") { return #err "Name is required" };
    let siteBucket = switch (Auth.getBucket(sites, ctx.tenantId)) {
      case null    { return #err "Site not found" };
      case (?b)    { b };
    };
    switch (Auth.validateRef(
      Map.get(siteBucket, Nat.compare, siteId),
      ctx.tenantId, "Site",
      func(s : Models.Site) : Nat { s.tenantId },
      func(s : Models.Site) : ?Int { s.deletedAt },
    )) {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    let now = Time.now();
    let zone : Models.Zone = {
      id          = nextId;
      tenantId    = ctx.tenantId;
      siteId      = siteId;
      name        = name;
      description = description;
      isActive    = true;
      createdAt   = now;
      updatedAt   = now;
      deletedAt   = null;
      version     = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, zone.id, zone);
    #ok zone
  };

  public func getZone(
    store : Auth.ZoneStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Zone; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Zone not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Zone not found" };
          case (?z)  {
            if (z.deletedAt != null) { return #err "Zone not found" };
            #ok z
          };
        }
      };
    }
  };

  public func listZones(
    store  : Auth.ZoneStore,
    ctx    : Auth.AuthContext,
    siteId : ?Nat,
  ) : [Models.Zone] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Zone>(0);
        for ((_, z) in Map.entries(bucket)) {
          if (z.deletedAt == null) {
            switch (siteId) {
              case null     { result.add(z) };
              case (?sid)   { if (z.siteId == sid) { result.add(z) } };
            };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func updateZone(
    store       : Auth.ZoneStore,
    ctx         : Auth.AuthContext,
    id          : Nat,
    name        : Text,
    description : ?Text,
  ) : { #ok : Models.Zone; #err : Text } {
    if (name == "") { return #err "Name is required" };
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Zone not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Zone not found" };
          case (?z)  {
            if (z.deletedAt != null) { return #err "Zone not found" };
            let updated : Models.Zone = {
              id          = z.id;
              tenantId    = z.tenantId;
              siteId      = z.siteId;
              name        = name;
              description = description;
              isActive    = z.isActive;
              createdAt   = z.createdAt;
              updatedAt   = Time.now();
              deletedAt   = z.deletedAt;
              version     = z.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteZone(
    store : Auth.ZoneStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Zone; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Zone not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Zone not found" };
          case (?z)  {
            if (z.deletedAt != null) { return #err "Zone not found" };
            let now = Time.now();
            let updated : Models.Zone = {
              id          = z.id;
              tenantId    = z.tenantId;
              siteId      = z.siteId;
              name        = z.name;
              description = z.description;
              isActive    = false;
              createdAt   = z.createdAt;
              updatedAt   = now;
              deletedAt   = ?now;
              version     = z.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};