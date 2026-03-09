import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  // ── AssetType ─────────────────────────────────────────────────────────────

  public func createAssetType(
    store       : Auth.AssetTypeStore,
    nextId      : Nat,
    ctx         : Auth.AuthContext,
    name        : Text,
    description : ?Text,
    familyId    : ?Text,
  ) : { #ok : Models.AssetType; #err : Text } {
    if (name == "") { return #err "Name is required" };
    let now = Time.now();
    let assetType : Models.AssetType = {
      id          = nextId;
      tenantId    = ctx.tenantId;
      name        = name;
      description = description;
      familyId    = familyId;
      isActive    = true;
      createdAt   = now;
      updatedAt   = now;
      deletedAt   = null;
      version     = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, assetType.id, assetType);
    #ok assetType
  };

  public func getAssetType(
    store : Auth.AssetTypeStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.AssetType; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset type not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null   { #err "Asset type not found" };
          case (?at) {
            if (at.deletedAt != null) { return #err "Asset type not found" };
            #ok at
          };
        }
      };
    }
  };

  public func listAssetTypes(
    store : Auth.AssetTypeStore,
    ctx   : Auth.AuthContext,
  ) : [Models.AssetType] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.AssetType>(0);
        for ((_, at) in Map.entries(bucket)) {
          if (at.deletedAt == null) { result.add(at) };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func updateAssetType(
    store       : Auth.AssetTypeStore,
    ctx         : Auth.AuthContext,
    id          : Nat,
    name        : Text,
    description : ?Text,
  ) : { #ok : Models.AssetType; #err : Text } {
    if (name == "") { return #err "Name is required" };
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset type not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null   { #err "Asset type not found" };
          case (?at) {
            if (at.deletedAt != null) { return #err "Asset type not found" };
            let updated : Models.AssetType = {
              id          = at.id;
              tenantId    = at.tenantId;
              name        = name;
              description = description;
              familyId    = at.familyId;
              isActive    = at.isActive;
              createdAt   = at.createdAt;
              updatedAt   = Time.now();
              deletedAt   = at.deletedAt;
              version     = at.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteAssetType(
    store : Auth.AssetTypeStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.AssetType; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset type not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null   { #err "Asset type not found" };
          case (?at) {
            if (at.deletedAt != null) { return #err "Asset type not found" };
            let now = Time.now();
            let updated : Models.AssetType = {
              id          = at.id;
              tenantId    = at.tenantId;
              name        = at.name;
              description = at.description;
              familyId    = at.familyId;
              isActive    = at.isActive;
              createdAt   = at.createdAt;
              updatedAt   = now;
              deletedAt   = ?now;
              version     = at.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  // ── Asset ─────────────────────────────────────────────────────────────────

  public func createAsset(
    store        : Auth.AssetStore,
    sites        : Auth.SiteStore,
    assetTypes   : Auth.AssetTypeStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    customerId   : Nat,
    siteId       : Nat,
    zoneId       : ?Nat,
    assetTypeId  : Nat,
    name         : Text,
    serialNumber : ?Text,
    installedAt  : ?Int,
  ) : { #ok : Models.Asset; #err : Text } {
    if (name == "") { return #err "Name is required" };
    // Validate site belongs to tenant
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
    // Validate asset type belongs to tenant
    let atBucket = switch (Auth.getBucket(assetTypes, ctx.tenantId)) {
      case null    { return #err "Asset type not found" };
      case (?b)    { b };
    };
    switch (Auth.validateRef(
      Map.get(atBucket, Nat.compare, assetTypeId),
      ctx.tenantId, "Asset type",
      func(at : Models.AssetType) : Nat { at.tenantId },
      func(at : Models.AssetType) : ?Int { at.deletedAt },
    )) {
      case (#err e) { return #err e };
      case (#ok _)  {};
    };
    let now = Time.now();
    let asset : Models.Asset = {
      id           = nextId;
      tenantId     = ctx.tenantId;
      customerId   = customerId;
      siteId       = siteId;
      zoneId       = zoneId;
      assetTypeId  = assetTypeId;
      name         = name;
      serialNumber = serialNumber;
      status       = #active;
      installedAt  = installedAt;
      createdAt    = now;
      updatedAt    = now;
      deletedAt    = null;
      version      = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, asset.id, asset);
    #ok asset
  };

  public func getAsset(
    store : Auth.AssetStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Asset; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Asset not found" };
          case (?a) {
            if (a.deletedAt != null) { return #err "Asset not found" };
            #ok a
          };
        }
      };
    }
  };

  public func listAssets(
    store      : Auth.AssetStore,
    ctx        : Auth.AuthContext,
    siteId     : ?Nat,
    customerId : ?Nat,
  ) : [Models.Asset] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Asset>(0);
        for ((_, a) in Map.entries(bucket)) {
          if (a.deletedAt == null) {
            let siteMatch = switch (siteId) {
              case null   { true };
              case (?sid) { a.siteId == sid };
            };
            let customerMatch = switch (customerId) {
              case null   { true };
              case (?cid) { a.customerId == cid };
            };
            if (siteMatch and customerMatch) { result.add(a) };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func updateAsset(
    store        : Auth.AssetStore,
    ctx          : Auth.AuthContext,
    id           : Nat,
    name         : Text,
    serialNumber : ?Text,
    zoneId       : ?Nat,
    assetTypeId  : Nat,
    installedAt  : ?Int,
  ) : { #ok : Models.Asset; #err : Text } {
    if (name == "") { return #err "Name is required" };
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Asset not found" };
          case (?a) {
            if (a.deletedAt != null) { return #err "Asset not found" };
            let updated : Models.Asset = {
              id           = a.id;
              tenantId     = a.tenantId;
              customerId   = a.customerId;
              siteId       = a.siteId;
              zoneId       = zoneId;
              assetTypeId  = assetTypeId;
              name         = name;
              serialNumber = serialNumber;
              status       = a.status;
              installedAt  = installedAt;
              createdAt    = a.createdAt;
              updatedAt    = Time.now();
              deletedAt    = a.deletedAt;
              version      = a.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func updateAssetStatus(
    store  : Auth.AssetStore,
    ctx    : Auth.AuthContext,
    id     : Nat,
    status : Models.AssetStatus,
  ) : { #ok : Models.Asset; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Asset not found" };
          case (?a) {
            if (a.deletedAt != null) { return #err "Asset not found" };
            let updated : Models.Asset = {
              id           = a.id;
              tenantId     = a.tenantId;
              customerId   = a.customerId;
              siteId       = a.siteId;
              zoneId       = a.zoneId;
              assetTypeId  = a.assetTypeId;
              name         = a.name;
              serialNumber = a.serialNumber;
              status       = status;
              installedAt  = a.installedAt;
              createdAt    = a.createdAt;
              updatedAt    = Time.now();
              deletedAt    = a.deletedAt;
              version      = a.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteAsset(
    store : Auth.AssetStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Asset; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Asset not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Asset not found" };
          case (?a) {
            if (a.deletedAt != null) { return #err "Asset not found" };
            let now = Time.now();
            let updated : Models.Asset = {
              id           = a.id;
              tenantId     = a.tenantId;
              customerId   = a.customerId;
              siteId       = a.siteId;
              zoneId       = a.zoneId;
              assetTypeId  = a.assetTypeId;
              name         = a.name;
              serialNumber = a.serialNumber;
              status       = a.status;
              installedAt  = a.installedAt;
              createdAt    = a.createdAt;
              updatedAt    = now;
              deletedAt    = ?now;
              version      = a.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};