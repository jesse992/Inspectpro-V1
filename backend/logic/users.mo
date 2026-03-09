import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Principal "mo:core/Principal";

module {

  public func createUser(
    users            : Map.Map<Nat, Models.User>,
    usersByPrincipal : Map.Map<Principal, Nat>,
    nextId           : Nat,
    tenantId         : Nat,
    principal        : Principal,
    role             : Models.Role,
    customerId       : ?Nat,
    name             : Text,
    email            : ?Text,
    phone            : ?Text,
  ) : { #ok : Models.User; #err : Text } {
    switch (Map.get(usersByPrincipal, Principal.compare, principal)) {
      case (?_) { #err "Principal already registered" };
      case null {
        let now = Time.now();
        let user : Models.User = {
          id                 = nextId;
          tenantId           = tenantId;
          principal          = principal;
          role               = role;
          customerId         = customerId;
          name               = name;
          email              = email;
          phone              = phone;
          avatarUrl          = null;
          isActive           = true;
          emailNotifications = true;
          inAppNotifications = true;
          theme              = "dark";
          lastLoginAt        = null;
          createdAt          = now;
          updatedAt          = now;
          deletedAt          = null;
          version            = 1;
        };
        Map.add(users, Nat.compare, user.id, user);
        Map.add(usersByPrincipal, Principal.compare, principal, user.id);
        #ok user
      };
    }
  };

  public func getUser(
    users : Map.Map<Nat, Models.User>,
    id    : Nat,
  ) : { #ok : Models.User; #err : Text } {
    switch (Map.get(users, Nat.compare, id)) {
      case null  { #err "User not found" };
      case (?u)  { #ok u };
    }
  };

  public func getUserByPrincipal(
    users            : Map.Map<Nat, Models.User>,
    usersByPrincipal : Map.Map<Principal, Nat>,
    principal        : Principal,
  ) : { #ok : Models.User; #err : Text } {
    switch (Map.get(usersByPrincipal, Principal.compare, principal)) {
      case null    { #err "User not found" };
      case (?uid)  {
        switch (Map.get(users, Nat.compare, uid)) {
          case null  { #err "User record missing" };
          case (?u)  { #ok u };
        }
      };
    }
  };

  public func listUsers(
    users    : Map.Map<Nat, Models.User>,
    tenantId : Nat,
  ) : [Models.User] {
    var result = Buffer.Buffer<Models.User>(0);
    for ((_, u) in Map.entries(users)) {
      if (u.tenantId == tenantId and u.deletedAt == null) {
        result.add(u);
      };
    };
    Buffer.toArray(result)
  };

  public func updateUser(
    users  : Map.Map<Nat, Models.User>,
    id     : Nat,
    name   : Text,
    email  : ?Text,
    phone  : ?Text,
    role   : Models.Role,
  ) : { #ok : Models.User; #err : Text } {
    switch (Map.get(users, Nat.compare, id)) {
      case null { #err "User not found" };
      case (?u) {
        let updated : Models.User = {
          id                 = u.id;
          tenantId           = u.tenantId;
          principal          = u.principal;
          role               = role;
          customerId         = u.customerId;
          name               = name;
          email              = email;
          phone              = phone;
          avatarUrl          = u.avatarUrl;
          isActive           = u.isActive;
          emailNotifications = u.emailNotifications;
          inAppNotifications = u.inAppNotifications;
          theme              = u.theme;
          lastLoginAt        = u.lastLoginAt;
          createdAt          = u.createdAt;
          updatedAt          = Time.now();
          deletedAt          = u.deletedAt;
          version            = u.version + 1;
        };
        Map.add(users, Nat.compare, id, updated);
        #ok updated
      };
    }
  };

  public func deactivateUser(
    users : Map.Map<Nat, Models.User>,
    id    : Nat,
  ) : { #ok : Models.User; #err : Text } {
    switch (Map.get(users, Nat.compare, id)) {
      case null { #err "User not found" };
      case (?u) {
        let updated : Models.User = {
          id                 = u.id;
          tenantId           = u.tenantId;
          principal          = u.principal;
          role               = u.role;
          customerId         = u.customerId;
          name               = u.name;
          email              = u.email;
          phone              = u.phone;
          avatarUrl          = u.avatarUrl;
          isActive           = false;
          emailNotifications = u.emailNotifications;
          inAppNotifications = u.inAppNotifications;
          theme              = u.theme;
          lastLoginAt        = u.lastLoginAt;
          createdAt          = u.createdAt;
          updatedAt          = Time.now();
          deletedAt          = u.deletedAt;
          version            = u.version + 1;
        };
        Map.add(users, Nat.compare, id, updated);
        #ok updated
      };
    }
  };

  public func recordLogin(
    users : Map.Map<Nat, Models.User>,
    id    : Nat,
  ) : { #ok : Models.User; #err : Text } {
    switch (Map.get(users, Nat.compare, id)) {
      case null { #err "User not found" };
      case (?u) {
        let updated : Models.User = {
          id                 = u.id;
          tenantId           = u.tenantId;
          principal          = u.principal;
          role               = u.role;
          customerId         = u.customerId;
          name               = u.name;
          email              = u.email;
          phone              = u.phone;
          avatarUrl          = u.avatarUrl;
          isActive           = u.isActive;
          emailNotifications = u.emailNotifications;
          inAppNotifications = u.inAppNotifications;
          theme              = u.theme;
          lastLoginAt        = ?Time.now();
          createdAt          = u.createdAt;
          updatedAt          = Time.now();
          deletedAt          = u.deletedAt;
          version            = u.version + 1;
        };
        Map.add(users, Nat.compare, id, updated);
        #ok updated
      };
    }
  };

};