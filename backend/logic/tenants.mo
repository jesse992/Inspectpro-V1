import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Time "mo:core/Time";
import Nat "mo:core/Nat";

module {

  public func createTenant(
    store      : Map.Map<Nat, Models.Tenant>,
    nextId     : Nat,
    name       : Text,
    tenantType : Models.TenantType,
  ) : Models.Tenant {
    let now = Time.now();
    let tenant : Models.Tenant = {
      id                         = nextId;
      name                       = name;
      tenantType                 = tenantType;
      status                     = #active;
      address                    = null;
      contactName                = null;
      contactEmail               = null;
      contactPhone               = null;
      logoUrl                    = null;
      websiteUrl                 = null;
      timezone                   = null;
      defaultPackId              = null;
      linkedTenantId             = null;
      notifyOnInspectionComplete = false;
      notifyOnInspectionFailed   = false;
      notifyDaysBeforeDue        = 0;
      createdAt                  = now;
      updatedAt                  = now;
      deletedAt                  = null;
      version                    = 1;
    };
    Map.add(store, Nat.compare, tenant.id, tenant);
    tenant
  };

  public func getTenant(
    store : Map.Map<Nat, Models.Tenant>,
    id    : Nat,
  ) : { #ok : Models.Tenant; #err : Text } {
    switch (Map.get(store, Nat.compare, id)) {
      case null  { #err "Tenant not found" };
      case (?t)  {
        if (t.deletedAt != null) { return #err "Tenant not found" };
        #ok t
      };
    }
  };

  public func listTenants(
    store : Map.Map<Nat, Models.Tenant>,
  ) : [Models.Tenant] {
    var result = Buffer.Buffer<Models.Tenant>(0);
    for ((_, t) in Map.entries(store)) {
      if (t.deletedAt == null) { result.add(t) };
    };
    Buffer.toArray(result)
  };

  public func updateTenant(
    store  : Map.Map<Nat, Models.Tenant>,
    id     : Nat,
    name   : Text,
    status : Models.TenantStatus,
  ) : { #ok : Models.Tenant; #err : Text } {
    switch (Map.get(store, Nat.compare, id)) {
      case null  { #err "Tenant not found" };
      case (?t)  {
        if (t.deletedAt != null) { return #err "Tenant not found" };
        let updated : Models.Tenant = {
          id                         = t.id;
          name                       = name;
          tenantType                 = t.tenantType;
          status                     = status;
          address                    = t.address;
          contactName                = t.contactName;
          contactEmail               = t.contactEmail;
          contactPhone               = t.contactPhone;
          logoUrl                    = t.logoUrl;
          websiteUrl                 = t.websiteUrl;
          timezone                   = t.timezone;
          defaultPackId              = t.defaultPackId;
          linkedTenantId             = t.linkedTenantId;
          notifyOnInspectionComplete = t.notifyOnInspectionComplete;
          notifyOnInspectionFailed   = t.notifyOnInspectionFailed;
          notifyDaysBeforeDue        = t.notifyDaysBeforeDue;
          createdAt                  = t.createdAt;
          updatedAt                  = Time.now();
          deletedAt                  = t.deletedAt;
          version                    = t.version + 1;
        };
        Map.add(store, Nat.compare, id, updated);
        #ok updated
      };
    }
  };

};