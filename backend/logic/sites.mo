import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public type SiteStore = Map.Map<Nat, Map.Map<Nat, Models.Site>>;

  // ── Create ────────────────────────────────────────────────────────────────

  public func createSite(
    store      : SiteStore,
    customers  : Auth.CustomerStore,
    nextId     : Nat,
    ctx        : Auth.AuthContext,
    name       : Text,
    address    : ?Text,
    customerId : Nat,
  ) : { #ok : Models.Site; #err : Text } {
    if (name == "") { return #err "Name is required" };
    let customerBucket = switch (Auth.getBucket(customers, ctx.tenantId)) {
      case null    { return #err "Customer not found" };
      case (?b)    { b };
    };
    switch (Auth.validateRef(
      Map.get(customerBucket, Nat.compare, customerId),
      ctx.tenantId, "Customer",
      func(s : Models.Customer) : Nat { s.tenantId },
      func(s : Models.Customer) : ?Int { s.deletedAt },
    )) {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    let now = Time.now();
    let site : Models.Site = {
      id         = nextId;
      tenantId   = ctx.tenantId;
      customerId = customerId;
      name       = name;
      address    = address;
      latitude   = null;
      longitude  = null;
      isActive   = true;
      createdAt  = now;
      updatedAt  = now;
      deletedAt  = null;
      version    = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, site.id, site);
    #ok site
  };

  // ── Read ──────────────────────────────────────────────────────────────────

  public func getSite(
    store : SiteStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Site; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Site not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null    { #err "Site not found" };
          case (?s) {
            if (s.deletedAt != null) { return #err "Site not found" };
            #ok s
          };
        }
      };
    }
  };

  public func listSites(
    store      : SiteStore,
    ctx        : Auth.AuthContext,
    customerId : ?Nat,
  ) : [Models.Site] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Site>(0);
        for ((_, s) in Map.entries(bucket)) {
          if (s.deletedAt == null) {
            switch (customerId) {
              case null     { result.add(s) };
              case (?cid)   { if (s.customerId == cid) { result.add(s) } };
            };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  // ── Update ────────────────────────────────────────────────────────────────

  public func updateSite(
    store   : SiteStore,
    ctx     : Auth.AuthContext,
    id      : Nat,
    name    : Text,
    address : ?Text,
  ) : { #ok : Models.Site; #err : Text } {
    if (name == "") { return #err "Name is required" };
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Site not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Site not found" };
          case (?s) {
            if (s.deletedAt != null) { return #err "Site not found" };
            let updated : Models.Site = {
              id         = s.id;
              tenantId   = s.tenantId;
              customerId = s.customerId;
              name       = name;
              address    = address;
              latitude   = s.latitude;
              longitude  = s.longitude;
              isActive   = s.isActive;
              createdAt  = s.createdAt;
              updatedAt  = Time.now();
              deletedAt  = s.deletedAt;
              version    = s.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  // ── Delete ────────────────────────────────────────────────────────────────

  public func deleteSite(
    store : SiteStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Site; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Site not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Site not found" };
          case (?s) {
            if (s.deletedAt != null) { return #err "Site not found" };
            let now = Time.now();
            let updated : Models.Site = {
              id         = s.id;
              tenantId   = s.tenantId;
              customerId = s.customerId;
              name       = s.name;
              address    = s.address;
              latitude   = s.latitude;
              longitude  = s.longitude;
              isActive   = s.isActive;
              createdAt  = s.createdAt;
              updatedAt  = now;
              deletedAt  = ?now;
              version    = s.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};