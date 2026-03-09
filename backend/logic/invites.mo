import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createInvite(
    invites       : Map.Map<Nat, Models.InviteCode>,
    invitesByCode : Map.Map<Text, Nat>,
    nextId        : Nat,
    tenantId      : Nat,
    createdBy     : Nat,
    role          : Models.Role,
    customerId    : ?Nat,
    code          : Text,
    expiresAt     : ?Int,
  ) : { #ok : Models.InviteCode; #err : Text } {
    switch (Map.get(invitesByCode, Text.compare, code)) {
      case (?_) { #err "Invite code already exists" };
      case null {
        let now = Time.now();
        let invite : Models.InviteCode = {
          id         = nextId;
          tenantId   = tenantId;
          createdBy  = createdBy;
          role       = role;
          customerId = customerId;
          code       = code;
          isActive   = true;
          expiresAt  = expiresAt;
          usedAt     = null;
          usedBy     = null;
          createdAt  = now;
          updatedAt  = now;
          deletedAt  = null;
          version    = 1;
        };
        Map.add(invites, Nat.compare, invite.id, invite);
        Map.add(invitesByCode, Text.compare, code, invite.id);
        #ok invite
      };
    }
  };

  public func getInvite(
    invites : Map.Map<Nat, Models.InviteCode>,
    id      : Nat,
  ) : { #ok : Models.InviteCode; #err : Text } {
    switch (Map.get(invites, Nat.compare, id)) {
      case null { #err "Invite not found" };
      case (?i) { #ok i };
    }
  };

  public func getInviteByCode(
    invites       : Map.Map<Nat, Models.InviteCode>,
    invitesByCode : Map.Map<Text, Nat>,
    code          : Text,
  ) : { #ok : Models.InviteCode; #err : Text } {
    switch (Map.get(invitesByCode, Text.compare, code)) {
      case null     { #err "Invite not found" };
      case (?invId) {
        switch (Map.get(invites, Nat.compare, invId)) {
          case null  { #err "Invite record missing" };
          case (?i)  { #ok i };
        }
      };
    }
  };

  public func listInvites(
    invites  : Map.Map<Nat, Models.InviteCode>,
    tenantId : Nat,
  ) : [Models.InviteCode] {
    var result = Buffer.Buffer<Models.InviteCode>(0);
    for ((_, i) in Map.entries(invites)) {
      if (i.tenantId == tenantId and i.deletedAt == null) {
        result.add(i);
      };
    };
    Buffer.toArray(result)
  };

  public func redeemInvite(
    invites       : Map.Map<Nat, Models.InviteCode>,
    invitesByCode : Map.Map<Text, Nat>,
    code          : Text,
    usedBy        : Nat,
  ) : { #ok : Models.InviteCode; #err : Text } {
    switch (Map.get(invitesByCode, Text.compare, code)) {
      case null     { #err "Invite not found" };
      case (?invId) {
        switch (Map.get(invites, Nat.compare, invId)) {
          case null  { #err "Invite record missing" };
          case (?i)  {
            if (not i.isActive) { return #err "Invite is no longer active" };
            switch (i.expiresAt) {
              case (?exp) {
                if (Time.now() > exp) { return #err "Invite expired" };
              };
              case null {};
            };
            let now = Time.now();
            let updated : Models.InviteCode = {
              id         = i.id;
              tenantId   = i.tenantId;
              createdBy  = i.createdBy;
              role       = i.role;
              customerId = i.customerId;
              code       = i.code;
              isActive   = false;
              expiresAt  = i.expiresAt;
              usedAt     = ?now;
              usedBy     = ?usedBy;
              createdAt  = i.createdAt;
              updatedAt  = now;
              deletedAt  = i.deletedAt;
              version    = i.version + 1;
            };
            Map.add(invites, Nat.compare, i.id, updated);
            #ok updated
          };
        }
      };
    }
  };

  public func cancelInvite(
    invites : Map.Map<Nat, Models.InviteCode>,
    id      : Nat,
  ) : { #ok : Models.InviteCode; #err : Text } {
    switch (Map.get(invites, Nat.compare, id)) {
      case null { #err "Invite not found" };
      case (?i) {
        if (not i.isActive) { return #err "Invite already inactive" };
        let updated : Models.InviteCode = {
          id         = i.id;
          tenantId   = i.tenantId;
          createdBy  = i.createdBy;
          role       = i.role;
          customerId = i.customerId;
          code       = i.code;
          isActive   = false;
          expiresAt  = i.expiresAt;
          usedAt     = i.usedAt;
          usedBy     = i.usedBy;
          createdAt  = i.createdAt;
          updatedAt  = Time.now();
          deletedAt  = i.deletedAt;
          version    = i.version + 1;
        };
        Map.add(invites, Nat.compare, i.id, updated);
        #ok updated
      };
    }
  };

};