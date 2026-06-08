export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      tenants: {
        Row: { id: string; name: string; slug: string; created_at: string };
        Insert: { id?: string; name: string; slug: string; created_at?: string };
        Update: { id?: string; name?: string; slug?: string; created_at?: string };
      };
      users: {
        Row: {
          id: string;
          tenant_id: string;
          auth_user_id: string;
          email: string;
          full_name: string;
          role: Database["public"]["Enums"]["app_role"];
          active: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          auth_user_id: string;
          email: string;
          full_name: string;
          role?: Database["public"]["Enums"]["app_role"];
          active?: boolean;
          created_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["users"]["Insert"]>;
      };
      studies: {
        Row: { id: string; tenant_id: string; protocol_number: string; title: string; phase: string | null; status: string; created_at: string };
        Insert: { id?: string; tenant_id: string; protocol_number: string; title: string; phase?: string | null; status?: string; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["studies"]["Insert"]>;
      };
      organizations: {
        Row: { id: string; tenant_id: string; name: string; kind: string; country: string; created_at: string };
        Insert: { id?: string; tenant_id: string; name: string; kind?: string; country?: string; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["organizations"]["Insert"]>;
      };
      sites: {
        Row: {
          id: string;
          tenant_id: string;
          study_id: string;
          organization_id: string;
          site_number: string;
          status: Database["public"]["Enums"]["site_status"];
          selected_at: string | null;
          ready_to_enroll_at: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          study_id: string;
          organization_id: string;
          site_number: string;
          status?: Database["public"]["Enums"]["site_status"];
          selected_at?: string | null;
          ready_to_enroll_at?: string | null;
          created_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["sites"]["Insert"]>;
      };
      people: {
        Row: { id: string; tenant_id: string; organization_id: string; full_name: string; email: string | null; npi: string | null; created_at: string };
        Insert: { id?: string; tenant_id: string; organization_id: string; full_name: string; email?: string | null; npi?: string | null; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["people"]["Insert"]>;
      };
      site_personnel: {
        Row: { id: string; tenant_id: string; site_id: string; person_id: string; role: Database["public"]["Enums"]["personnel_role"]; delegated_at: string; created_at: string };
        Insert: { id?: string; tenant_id: string; site_id: string; person_id: string; role: Database["public"]["Enums"]["personnel_role"]; delegated_at?: string; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["site_personnel"]["Insert"]>;
      };
      requirement_templates: {
        Row: {
          id: string;
          tenant_id: string | null;
          code: string;
          name: string;
          description: string | null;
          scope: Database["public"]["Enums"]["requirement_scope"];
          applies_to_role: Database["public"]["Enums"]["personnel_role"] | null;
          required: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          tenant_id?: string | null;
          code: string;
          name: string;
          description?: string | null;
          scope: Database["public"]["Enums"]["requirement_scope"];
          applies_to_role?: Database["public"]["Enums"]["personnel_role"] | null;
          required?: boolean;
          created_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["requirement_templates"]["Insert"]>;
      };
      requirement_instances: {
        Row: { id: string; tenant_id: string; site_id: string; template_id: string; person_id: string | null; status: Database["public"]["Enums"]["requirement_status"]; satisfied_at: string | null; created_at: string };
        Insert: { id?: string; tenant_id: string; site_id: string; template_id: string; person_id?: string | null; status?: Database["public"]["Enums"]["requirement_status"]; satisfied_at?: string | null; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["requirement_instances"]["Insert"]>;
      };
      documents: {
        Row: { id: string; tenant_id: string; owner_type: Database["public"]["Enums"]["document_owner_type"]; owner_id: string; title: string; document_type: string; current_version: number; created_at: string };
        Insert: { id?: string; tenant_id: string; owner_type: Database["public"]["Enums"]["document_owner_type"]; owner_id: string; title: string; document_type: string; current_version?: number; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["documents"]["Insert"]>;
      };
      document_versions: {
        Row: {
          id: string;
          tenant_id: string;
          document_id: string;
          version: number;
          storage_path: string;
          checksum: string;
          mime_type: string;
          byte_size: number;
          uploaded_via: Database["public"]["Enums"]["uploaded_via"];
          uploaded_by: string | null;
          received_at: string;
          metadata: Json;
        };
        Insert: {
          id?: string;
          tenant_id: string;
          document_id: string;
          version: number;
          storage_path: string;
          checksum: string;
          mime_type: string;
          byte_size: number;
          uploaded_via: Database["public"]["Enums"]["uploaded_via"];
          uploaded_by?: string | null;
          received_at?: string;
          metadata?: Json;
        };
        Update: never;
      };
      requirement_fulfillments: {
        Row: { id: string; tenant_id: string; requirement_instance_id: string; document_version_id: string; status: Database["public"]["Enums"]["fulfillment_status"]; decided_by: string | null; decided_at: string | null; created_at: string };
        Insert: { id?: string; tenant_id: string; requirement_instance_id: string; document_version_id: string; status?: Database["public"]["Enums"]["fulfillment_status"]; decided_by?: string | null; decided_at?: string | null; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["requirement_fulfillments"]["Insert"]>;
      };
      findings: {
        Row: { id: string; tenant_id: string; site_id: string | null; requirement_instance_id: string | null; severity: Database["public"]["Enums"]["finding_severity"]; code: string; message: string; asserted_state: Json; evidence_summary: Json; disposition: Database["public"]["Enums"]["finding_disposition"]; disposition_changed_by: string | null; disposition_changed_at: string | null; created_at: string };
        Insert: { id?: string; tenant_id: string; site_id?: string | null; requirement_instance_id?: string | null; severity?: Database["public"]["Enums"]["finding_severity"]; code: string; message: string; asserted_state?: Json; evidence_summary?: Json; disposition?: Database["public"]["Enums"]["finding_disposition"]; disposition_changed_by?: string | null; disposition_changed_at?: string | null; created_at?: string };
        Update: { disposition?: Database["public"]["Enums"]["finding_disposition"]; disposition_changed_by?: string | null; disposition_changed_at?: string | null };
      };
      finding_evidence: {
        Row: { id: string; tenant_id: string; finding_id: string; document_version_id: string | null; page_number: number | null; excerpt: string | null; metadata: Json; created_at: string };
        Insert: { id?: string; tenant_id: string; finding_id: string; document_version_id?: string | null; page_number?: number | null; excerpt?: string | null; metadata?: Json; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["finding_evidence"]["Insert"]>;
      };
      irbs: {
        Row: { id: string; name: string; kind: string; website: string | null; created_at: string };
        Insert: { id?: string; name: string; kind?: string; website?: string | null; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["irbs"]["Insert"]>;
      };
      irb_submissions: {
        Row: { id: string; tenant_id: string; study_id: string; site_id: string | null; irb_id: string; status: Database["public"]["Enums"]["irb_submission_status"]; assembled_at: string | null; submitted_at: string | null; created_at: string };
        Insert: { id?: string; tenant_id: string; study_id: string; site_id?: string | null; irb_id: string; status?: Database["public"]["Enums"]["irb_submission_status"]; assembled_at?: string | null; submitted_at?: string | null; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["irb_submissions"]["Insert"]>;
      };
      upload_tokens: {
        Row: { id: string; tenant_id: string; token_hash: string; document_id: string | null; owner_type: Database["public"]["Enums"]["document_owner_type"]; owner_id: string; purpose: string; expires_at: string; used_at: string | null; created_by: string | null; created_at: string };
        Insert: { id?: string; tenant_id: string; token_hash: string; document_id?: string | null; owner_type: Database["public"]["Enums"]["document_owner_type"]; owner_id: string; purpose: string; expires_at: string; used_at?: string | null; created_by?: string | null; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["upload_tokens"]["Insert"]>;
      };
      audit_events: {
        Row: { id: string; tenant_id: string; seq: number; prev_hash: string | null; hash: string; actor_user_id: string | null; action: string; entity_type: string; entity_id: string | null; payload: Json; created_at: string };
        Insert: { id?: string; tenant_id: string; seq: number; prev_hash?: string | null; hash: string; actor_user_id?: string | null; action: string; entity_type: string; entity_id?: string | null; payload?: Json; created_at?: string };
        Update: never;
      };
      signature_records: {
        Row: { id: string; tenant_id: string; audit_event_id: string; signer_user_id: string; meaning: string; created_at: string };
        Insert: { id?: string; tenant_id: string; audit_event_id: string; signer_user_id: string; meaning: string; created_at?: string };
        Update: Partial<Database["public"]["Tables"]["signature_records"]["Insert"]>;
      };
    };
    Views: Record<string, never>;
    Functions: {
      current_tenant_id: { Args: Record<string, never>; Returns: string | null };
      current_user_role: { Args: Record<string, never>; Returns: Database["public"]["Enums"]["app_role"] | null };
      custom_access_token_hook: { Args: { event: Json }; Returns: Json };
    };
    Enums: {
      app_role: "admin" | "manager" | "cta" | "viewer";
      site_status: "selected" | "collecting" | "reviewing" | "ready_to_enroll" | "stalled";
      personnel_role: "pi" | "sub_i" | "coordinator" | "pharmacist" | "other";
      requirement_scope: "site" | "person";
      requirement_status: "missing" | "pending_review" | "satisfied" | "waived";
      document_owner_type: "organization" | "person" | "site" | "study";
      uploaded_via: "user" | "token" | "worker";
      fulfillment_status: "proposed" | "accepted" | "rejected";
      finding_severity: "info" | "warning" | "critical";
      finding_disposition: "open" | "accepted" | "dismissed";
      irb_submission_status: "draft" | "assembled" | "submitted" | "approved" | "rejected";
    };
    CompositeTypes: Record<string, never>;
  };
};
