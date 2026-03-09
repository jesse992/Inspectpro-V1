import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createPack(
    store        : Auth.PackStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    name         : Text,
    description  : ?Text,
    assetTypeId  : ?Nat,
    fields       : [Models.PackField],
    passMax      : ?Nat,
    attentionMax : ?Nat,
  ) : { #ok : Models.Pack; #err : Text } {
    if (name == "") { return #err "Name is required" };
    let now = Time.now();
    let pack : Models.Pack = {
      id                     = nextId;
      tenantId               = ctx.tenantId;
      name                   = name;
      description            = description;
      assetTypeId            = assetTypeId;
      fields                 = fields;
      passMax                = passMax;
      attentionMax           = attentionMax;
      packVersion            = 1;
      parentPackId           = null;
      createdBy              = ctx.userId;
      isActive               = true;
      requiresCertification  = false;
      requiresGPS            = false;
      requiresPhotos         = false;
      requiresSignature      = false;
      createdAt              = now;
      updatedAt              = now;
      deletedAt              = null;
      version                = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, pack.id, pack);
    #ok pack
  };

  public func getPack(
    store : Auth.PackStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Pack; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Pack not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Pack not found" };
          case (?p) {
            if (p.deletedAt != null) { return #err "Pack not found" };
            #ok p
          };
        }
      };
    }
  };

  public func listPacks(
    store       : Auth.PackStore,
    ctx         : Auth.AuthContext,
    assetTypeId : ?Nat,
  ) : [Models.Pack] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Pack>(0);
        for ((_, p) in Map.entries(bucket)) {
          if (p.deletedAt == null and p.isActive) {
            switch (assetTypeId) {
              case null     { result.add(p) };
              case (?atid)  {
                switch (p.assetTypeId) {
                  case null       { result.add(p) };
                  case (?packAt)  { if (packAt == atid) { result.add(p) } };
                }
              };
            };
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func updatePackMetadata(
    store       : Auth.PackStore,
    ctx         : Auth.AuthContext,
    id          : Nat,
    name        : Text,
    description : ?Text,
    isActive    : Bool,
  ) : { #ok : Models.Pack; #err : Text } {
    if (name == "") { return #err "Name is required" };
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Pack not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Pack not found" };
          case (?p) {
            if (p.deletedAt != null) { return #err "Pack not found" };
            let updated : Models.Pack = {
              id                     = p.id;
              tenantId               = p.tenantId;
              name                   = name;
              description            = description;
              assetTypeId            = p.assetTypeId;
              fields                 = p.fields;
              passMax                = p.passMax;
              attentionMax           = p.attentionMax;
              packVersion            = p.packVersion;
              parentPackId           = p.parentPackId;
              createdBy              = p.createdBy;
              isActive               = isActive;
              requiresCertification  = p.requiresCertification;
              requiresGPS            = p.requiresGPS;
              requiresPhotos         = p.requiresPhotos;
              requiresSignature      = p.requiresSignature;
              createdAt              = p.createdAt;
              updatedAt              = Time.now();
              deletedAt              = p.deletedAt;
              version                = p.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func updatePackSchema(
    store        : Auth.PackStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    id           : Nat,
    fields       : [Models.PackField],
    passMax      : ?Nat,
    attentionMax : ?Nat,
  ) : { #ok : Models.Pack; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Pack not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Pack not found" };
          case (?p) {
            if (p.deletedAt != null) { return #err "Pack not found" };
            let now = Time.now();
            let archived : Models.Pack = {
              id                     = p.id;
              tenantId               = p.tenantId;
              name                   = p.name;
              description            = p.description;
              assetTypeId            = p.assetTypeId;
              fields                 = p.fields;
              passMax                = p.passMax;
              attentionMax           = p.attentionMax;
              packVersion            = p.packVersion;
              parentPackId           = p.parentPackId;
              createdBy              = p.createdBy;
              isActive               = false;
              requiresCertification  = p.requiresCertification;
              requiresGPS            = p.requiresGPS;
              requiresPhotos         = p.requiresPhotos;
              requiresSignature      = p.requiresSignature;
              createdAt              = p.createdAt;
              updatedAt              = now;
              deletedAt              = ?now;
              version                = p.version + 1;
            };
            Map.add(bucket, Nat.compare, id, archived);
            let newPack : Models.Pack = {
              id                     = nextId;
              tenantId               = p.tenantId;
              name                   = p.name;
              description            = p.description;
              assetTypeId            = p.assetTypeId;
              fields                 = fields;
              passMax                = passMax;
              attentionMax           = attentionMax;
              packVersion            = p.packVersion + 1;
              parentPackId           = ?p.id;
              createdBy              = p.createdBy;
              isActive               = true;
              requiresCertification  = p.requiresCertification;
              requiresGPS            = p.requiresGPS;
              requiresPhotos         = p.requiresPhotos;
              requiresSignature      = p.requiresSignature;
              createdAt              = now;
              updatedAt              = now;
              deletedAt              = null;
              version                = 1;
            };
            Map.add(bucket, Nat.compare, nextId, newPack);
            #ok newPack
          };
        }
      };
    }
  };

  public func deletePack(
    store : Auth.PackStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Pack; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Pack not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Pack not found" };
          case (?p) {
            if (p.deletedAt != null) { return #err "Pack not found" };
            let now = Time.now();
            let updated : Models.Pack = {
              id                     = p.id;
              tenantId               = p.tenantId;
              name                   = p.name;
              description            = p.description;
              assetTypeId            = p.assetTypeId;
              fields                 = p.fields;
              passMax                = p.passMax;
              attentionMax           = p.attentionMax;
              packVersion            = p.packVersion;
              parentPackId           = p.parentPackId;
              createdBy              = p.createdBy;
              isActive               = false;
              requiresCertification  = p.requiresCertification;
              requiresGPS            = p.requiresGPS;
              requiresPhotos         = p.requiresPhotos;
              requiresSignature      = p.requiresSignature;
              createdAt              = p.createdAt;
              updatedAt              = now;
              deletedAt              = ?now;
              version                = p.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};