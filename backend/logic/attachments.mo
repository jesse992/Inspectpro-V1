import Buffer "mo:base/Buffer";
import Map "mo:core/Map";
import Models "../data/models";
import Auth "../authorization/lib";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public func createAttachment(
    store      : Auth.AttachmentStore,
    nextId     : Nat,
    ctx        : Auth.AuthContext,
    entityType : Models.AttachmentEntityType,
    entityId   : Nat,
    fileName   : Text,
    mimeType   : ?Text,
    storageUrl : Text,
    sizeBytes  : ?Nat,
  ) : { #ok : Models.Attachment; #err : Text } {
    if (fileName == "")   { return #err "File name is required" };
    if (storageUrl == "") { return #err "URL is required" };
    let now = Time.now();
    let attachment : Models.Attachment = {
      id         = nextId;
      tenantId   = ctx.tenantId;
      entityType = entityType;
      entityId   = entityId;
      fileName   = fileName;
      mimeType   = mimeType;
      storageUrl = storageUrl;
      uploadedBy = ctx.userId;
      sizeBytes  = sizeBytes;
      createdAt  = now;
      updatedAt  = now;
      deletedAt  = null;
      version    = 1;
    };
    let bucket = Auth.getOrCreateBucket(store, ctx.tenantId);
    Map.add(bucket, Nat.compare, attachment.id, attachment);
    #ok attachment
  };

  public func getAttachment(
    store : Auth.AttachmentStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Attachment; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Attachment not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Attachment not found" };
          case (?a) {
            if (a.deletedAt != null) { return #err "Attachment not found" };
            #ok a
          };
        }
      };
    }
  };

  public func listAttachmentsByEntity(
    store    : Auth.AttachmentStore,
    ctx      : Auth.AuthContext,
    entityId : Nat,
  ) : [Models.Attachment] {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { [] };
      case (?bucket) {
        var result = Buffer.Buffer<Models.Attachment>(0);
        for ((_, a) in Map.entries(bucket)) {
          if (a.entityId == entityId and a.deletedAt == null) {
            result.add(a)
          };
        };
        Buffer.toArray(result)
      };
    }
  };

  public func deleteAttachment(
    store : Auth.AttachmentStore,
    ctx   : Auth.AuthContext,
    id    : Nat,
  ) : { #ok : Models.Attachment; #err : Text } {
    switch (Auth.getBucket(store, ctx.tenantId)) {
      case null      { #err "Attachment not found" };
      case (?bucket) {
        switch (Map.get(bucket, Nat.compare, id)) {
          case null  { #err "Attachment not found" };
          case (?a) {
            if (a.deletedAt != null) { return #err "Attachment not found" };
            let now = Time.now();
            let updated : Models.Attachment = {
              id         = a.id;
              tenantId   = a.tenantId;
              entityType = a.entityType;
              entityId   = a.entityId;
              fileName   = a.fileName;
              mimeType   = a.mimeType;
              storageUrl = a.storageUrl;
              uploadedBy = a.uploadedBy;
              sizeBytes  = a.sizeBytes;
              createdAt  = a.createdAt;
              updatedAt  = now;
              deletedAt  = ?now;
              version    = a.version + 1;
            };
            Map.add(bucket, Nat.compare, id, updated);
            #ok updated
          };
        }
      };
    }
  };

};