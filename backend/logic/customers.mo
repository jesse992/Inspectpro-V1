import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createCustomer(
    store        : Auth.CustomerStore,
    nextId       : Nat,
    ctx          : Auth.AuthContext,
    name         : Text,
    contactName  : ?Text,
    contactEmail : ?Text,
    contactPhone : ?Text,
    address      : ?Text,
  ) : { #ok : Models.Customer; #err : Text } {
    if (name == "") { return #err "Name is required" };
    let now = Time.now();
    let customer : Models.Customer = {
      id             = nextId;
      tenantId       = ctx.tenantId;
      name           = name;
      contactName    = contactName;
      contactEmail   = contactEmail;
      contactPhone   = contactPhone;
      address        = address;
      logoUrl        = null;
      linkedTenantId = null;
      isActive       = true;
      createdAt      = now;
      updatedAt      = now;
      deletedAt      = null;
      version        = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, customer.id, customer);
    #ok customer
  };

  public func getCustomer(
    store : Auth.CustomerStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Customer; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Customer not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null { #err "Customer not found" };
          case (?c) {
            if (c.deletedAt != null) { return #err "Customer not found" };
            #ok c
          };
        }
      };
    }
  };

  public func listCustomers(
    store : Auth.CustomerStore,
    ctx   : Auth.AuthContext,
  ) : [Models.Customer] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Customer>(0);
        for ((_, c) in Map.entries(bucket)) {
          if (c.deletedAt == null) { result.add(c) };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func updateCustomer(
    store        : Auth.CustomerStore,
    ctx          : Auth.AuthContext,
    id           : Nat,
    name         : Text,
    contactName  : ?Text,
    contactEmail : ?Text,
    contactPhone : ?Text,
    address      : ?Text,
  ) : { #ok : Models.Customer; #err : Text } {
    if (name == "") { return #err "Name is required" };
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Customer not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null { #err "Customer not found" };
          case (?c) {
            if (c.deletedAt != null) { return #err "Customer not found" };
            let updated : Models.Customer = {
              id             = c.id;
              tenantId       = c.tenantId;
              name           = name;
              contactName    = contactName;
              contactEmail   = contactEmail;
              contactPhone   = contactPhone;
              address        = address;
              logoUrl        = c.logoUrl;
              linkedTenantId = c.linkedTenantId;
              isActive       = c.isActive;
              createdAt      = c.createdAt;
              updatedAt      = Time.now();
              deletedAt      = c.deletedAt;
              version        = c.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func deleteCustomer(
    store : Auth.CustomerStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Customer; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Customer not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null { #err "Customer not found" };
          case (?c) {
            if (c.deletedAt != null) { return #err "Customer not found" };
            let now = Time.now();
            let updated : Models.Customer = {
              id             = c.id;
              tenantId       = c.tenantId;
              name           = c.name;
              contactName    = c.contactName;
              contactEmail   = c.contactEmail;
              contactPhone   = c.contactPhone;
              address        = c.address;
              logoUrl        = c.logoUrl;
              linkedTenantId = c.linkedTenantId;
              isActive       = c.isActive;
              createdAt      = c.createdAt;
              updatedAt      = now;
              deletedAt      = ?now;
              version        = c.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};