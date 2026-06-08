export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type AppRole = "admin" | "manager" | "cta" | "viewer";
export type TenantKind = "sponsor" | "cro";
export type SiteStatus = "selected" | "activating" | "ready" | "on_hold" | "withdrawn";
export type StudyStatus = "active" | "closed" | "on_hold";
export type PersonnelRole = "pi" | "sub_i" | "coordinator" | "pharmacist" | "other";
export type RequirementScope = "site" | "person";
export type RequirementStatus =
  | "pending"
  | "requested"
  | "received"
  | "under_review"
  | "satisfied"
  | "rejected"
  | "waived";
export type DocumentOwnerType = "organization" | "person" | "site" | "study";
export type DocumentStatus = "active" | "superseded" | "withdrawn";
export type UploadedVia = "user" | "token";
export type FulfillmentStatus = "proposed" | "accepted" | "rejected";
export type FindingSeverity = "info" | "warning" | "blocker";
export type FindingSource = "system" | "user";
export type FindingDisposition = "open" | "accepted" | "dismissed";
export type IrbKind = "central" | "local";
export type IrbSubmissionStatus =
  | "draft"
  | "assembled"
  | "submitted"
  | "approved"
  | "rejected"
  | "changes_requested";

export type Database = {
  public: {
    Tables: {
      tenants: {
        Row: {
          id: string;
          name: string;
          kind: TenantKind;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          kind?: TenantKind;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["tenants"]["Insert"]>;
      };
      users: {
        Row: {
          id: string;
          tenant_id: string;
          email: string;
          full_name: string | null;
          role: AppRole;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          tenant_id: string;
          email: string;
          full_name?: string | null;
          role?: AppRole;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["users"]["Insert"]>;
      };
      studies: {
        Row: {
          id: string;
          tenant_id: string;
          name: string;
          protocol_version: string | null;
          protocol_doc_id: string | null;
          target_ready_date: string | null;
          status: StudyStatus;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          name: string;
          protocol_version?: string | null;
          protocol_doc_id?: string | null;
          target_ready_date?: string | null;
          status?: StudyStatus;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["studies"]["Insert"]>;
      };
      organizations: {
        Row: {
          id: string;
          tenant_id: string;
          name: string;
          country: string;
          ctms_ref: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          name: string;
          country: string;
          ctms_ref?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["organizations"]["Insert"]>;
      };
      sites: {
        Row: {
          id: string;
          tenant_id: string;
          study_id: string;
          organization_id: string;
          irb_id: string | null;
          status: SiteStatus;
          selected_at: string | null;
          projected_ready_date: string | null;
          activated_at: string | null;
          baseline_days: number | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          study_id: string;
          organization_id: string;
          irb_id?: string | null;
          status?: SiteStatus;
          selected_at?: string | null;
          projected_ready_date?: string | null;
          activated_at?: string | null;
          baseline_days?: number | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["sites"]["Insert"]>;
      };
      people: {
        Row: {
          id: string;
          tenant_id: string;
          organization_id: string;
          full_name: string;
          email: string | null;
          npi: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          organization_id: string;
          full_name: string;
          email?: string | null;
          npi?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["people"]["Insert"]>;
      };
      site_personnel: {
        Row: {
          id: string;
          tenant_id: string;
          site_id: string;
          person_id: string;
          role: PersonnelRole;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          site_id: string;
          person_id: string;
          role: PersonnelRole;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["site_personnel"]["Insert"]>;
      };
      requirement_templates: {
        Row: {
          id: string;
          tenant_id: string | null;
          name: string;
          doc_type: string;
          scope: RequirementScope;
          country: string | null;
          irb_kind: string | null;
          applies_to_role: PersonnelRole | null;
          rule_json: Json;
          expiry_relevant: boolean;
          embedding: string | null;
          version: number;
          active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id?: string | null;
          name: string;
          doc_type: string;
          scope: RequirementScope;
          country?: string | null;
          irb_kind?: string | null;
          applies_to_role?: PersonnelRole | null;
          rule_json?: Json;
          expiry_relevant?: boolean;
          embedding?: string | null;
          version?: number;
          active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["requirement_templates"]["Insert"]>;
      };
      requirement_instances: {
        Row: {
          id: string;
          tenant_id: string;
          site_id: string;
          person_id: string | null;
          template_id: string;
          status: RequirementStatus;
          required_by_date: string | null;
          satisfied_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          site_id: string;
          person_id?: string | null;
          template_id: string;
          status?: RequirementStatus;
          required_by_date?: string | null;
          satisfied_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["requirement_instances"]["Insert"]>;
      };
      documents: {
        Row: {
          id: string;
          tenant_id: string;
          owner_type: DocumentOwnerType;
          owner_id: string;
          doc_type: string;
          title: string | null;
          status: DocumentStatus;
          current_version: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          owner_type: DocumentOwnerType;
          owner_id: string;
          doc_type: string;
          title?: string | null;
          status?: DocumentStatus;
          current_version?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["documents"]["Insert"]>;
      };
      document_versions: {
        Row: {
          id: string;
          tenant_id: string;
          document_id: string;
          version: number;
          storage_path: string;
          content_type: string | null;
          page_count: number | null;
          checksum: string;
          uploaded_via: UploadedVia;
          uploaded_by: string | null;
          uploaded_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          document_id: string;
          version: number;
          storage_path: string;
          content_type?: string | null;
          page_count?: number | null;
          checksum: string;
          uploaded_via?: UploadedVia;
          uploaded_by?: string | null;
          uploaded_at?: string;
        };
        Update: never;
      };
      requirement_fulfillments: {
        Row: {
          id: string;
          tenant_id: string;
          requirement_instance_id: string;
          document_version_id: string;
          status: FulfillmentStatus;
          decided_by: string | null;
          decided_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          requirement_instance_id: string;
          document_version_id: string;
          status?: FulfillmentStatus;
          decided_by?: string | null;
          decided_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["requirement_fulfillments"]["Insert"]>;
      };
      upload_tokens: {
        Row: {
          id: string;
          tenant_id: string;
          site_id: string;
          requirement_instance_id: string | null;
          token_hash: string;
          expires_at: string;
          used_at: string | null;
          revoked: boolean;
          created_by: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          site_id: string;
          requirement_instance_id?: string | null;
          token_hash: string;
          expires_at: string;
          used_at?: string | null;
          revoked?: boolean;
          created_by?: string | null;
          created_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["upload_tokens"]["Insert"]>;
      };
      findings: {
        Row: {
          id: string;
          tenant_id: string;
          site_id: string | null;
          requirement_instance_id: string | null;
          type: string;
          severity: FindingSeverity;
          confidence: number;
          detail: string | null;
          source: FindingSource;
          disposition: FindingDisposition;
          disposition_changed_by: string | null;
          disposition_changed_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          site_id?: string | null;
          requirement_instance_id?: string | null;
          type: string;
          severity?: FindingSeverity;
          confidence: number;
          detail?: string | null;
          source?: FindingSource;
          disposition?: FindingDisposition;
          disposition_changed_by?: string | null;
          disposition_changed_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          disposition?: FindingDisposition;
          disposition_changed_by?: string | null;
          disposition_changed_at?: string | null;
        };
      };
      finding_evidence: {
        Row: {
          id: string;
          tenant_id: string;
          finding_id: string;
          document_version_id: string;
          page: number | null;
          field: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          finding_id: string;
          document_version_id: string;
          page?: number | null;
          field?: string | null;
          created_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["finding_evidence"]["Insert"]>;
      };
      irbs: {
        Row: {
          id: string;
          name: string;
          kind: IrbKind;
          config_json: Json;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          kind: IrbKind;
          config_json?: Json;
          created_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["irbs"]["Insert"]>;
      };
      irb_submissions: {
        Row: {
          id: string;
          tenant_id: string;
          site_id: string;
          irb_id: string;
          status: IrbSubmissionStatus;
          icf_version: string | null;
          package_storage_path: string | null;
          submitted_at: string | null;
          approved_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          site_id: string;
          irb_id: string;
          status?: IrbSubmissionStatus;
          icf_version?: string | null;
          package_storage_path?: string | null;
          submitted_at?: string | null;
          approved_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["irb_submissions"]["Insert"]>;
      };
      audit_events: {
        Row: {
          id: string;
          tenant_id: string;
          seq: number;
          actor: string;
          action: string;
          entity_type: string;
          entity_id: string | null;
          payload: Json;
          prev_hash: string | null;
          hash: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          seq: number;
          actor: string;
          action: string;
          entity_type: string;
          entity_id?: string | null;
          payload?: Json;
          prev_hash?: string | null;
          hash: string;
          created_at?: string;
        };
        Update: never;
      };
      signature_records: {
        Row: {
          id: string;
          tenant_id: string;
          entity_type: string;
          entity_id: string;
          signer: string;
          meaning: string;
          signature_hash: string | null;
          signed_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          entity_type: string;
          entity_id: string;
          signer: string;
          meaning: string;
          signature_hash?: string | null;
          signed_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["signature_records"]["Insert"]>;
      };
    };
    Views: Record<string, never>;
    Functions: {
      current_tenant_id: { Args: Record<string, never>; Returns: string | null };
      current_user_role: { Args: Record<string, never>; Returns: AppRole | null };
      current_user_is_one_of: { Args: { allowed_roles: string[] }; Returns: boolean };
      custom_access_token_hook: { Args: { event: Json }; Returns: Json };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
