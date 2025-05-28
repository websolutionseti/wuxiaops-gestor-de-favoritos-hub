--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.12 (Debian 15.12-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: get_user_stats(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_stats(user_uuid uuid) RETURNS TABLE(total_bookmarks bigint, total_folders bigint, total_links bigint, total_tags bigint, most_used_tags text[])
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM public.bookmarks WHERE user_id = user_uuid),
    (SELECT COUNT(*) FROM public.bookmarks WHERE user_id = user_uuid AND type = 'folder'),
    (SELECT COUNT(*) FROM public.bookmarks WHERE user_id = user_uuid AND type = 'link'),
    (SELECT COUNT(*) FROM public.tags WHERE created_by = user_uuid),
    (SELECT ARRAY_AGG(name ORDER BY usage_count DESC) 
     FROM (
       SELECT t.name, COUNT(*) as usage_count
       FROM public.tags t
       JOIN public.bookmark_tags bt ON t.id = bt.tag_id
       JOIN public.bookmarks b ON bt.bookmark_id = b.id
       WHERE b.user_id = user_uuid
       GROUP BY t.name
       ORDER BY usage_count DESC
       LIMIT 10
     ) top_tags);
END;
$$;


ALTER FUNCTION public.get_user_stats(user_uuid uuid) OWNER TO postgres;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (NEW.id, NEW.raw_user_meta_data ->> 'name');
  
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: log_bookmark_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_bookmark_changes() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_log (user_id, action, target_table, target_id, new_values)
    VALUES (NEW.user_id, 'CREATE', 'bookmarks', NEW.id, to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO public.audit_log (user_id, action, target_table, target_id, old_values, new_values)
    VALUES (NEW.user_id, 'UPDATE', 'bookmarks', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO public.audit_log (user_id, action, target_table, target_id, old_values)
    VALUES (OLD.user_id, 'DELETE', 'bookmarks', OLD.id, to_jsonb(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.log_bookmark_changes() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    action text NOT NULL,
    target_table text NOT NULL,
    target_id uuid,
    old_values jsonb,
    new_values jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: backups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    filename text NOT NULL,
    file_size integer,
    backup_type text DEFAULT 'manual'::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT backups_backup_type_check CHECK ((backup_type = ANY (ARRAY['manual'::text, 'automatic'::text]))),
    CONSTRAINT backups_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text])))
);


ALTER TABLE public.backups OWNER TO postgres;

--
-- Name: bookmark_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookmark_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bookmark_id uuid NOT NULL,
    tag_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.bookmark_tags OWNER TO postgres;

--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookmarks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    url text,
    icon text,
    type text DEFAULT 'link'::text NOT NULL,
    parent_id uuid,
    description text,
    tags text[],
    order_index integer DEFAULT 0 NOT NULL,
    is_favorite boolean DEFAULT false NOT NULL,
    visit_count integer DEFAULT 0 NOT NULL,
    last_visited_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT bookmarks_title_check CHECK ((((type = 'link'::text) AND (title IS NOT NULL) AND (TRIM(BOTH FROM title) <> ''::text)) OR ((type = 'folder'::text) AND (title IS NOT NULL) AND (TRIM(BOTH FROM title) <> ''::text)))),
    CONSTRAINT bookmarks_type_check CHECK ((type = ANY (ARRAY['folder'::text, 'link'::text])))
);


ALTER TABLE public.bookmarks OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    name text,
    avatar_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    color text DEFAULT '#8B5CF6'::text,
    description text,
    created_by uuid,
    is_shared boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tags OWNER TO postgres;

--
-- Name: user_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    theme text DEFAULT 'system'::text NOT NULL,
    default_view text DEFAULT 'tree'::text NOT NULL,
    items_per_page integer DEFAULT 50 NOT NULL,
    auto_backup boolean DEFAULT true NOT NULL,
    backup_frequency text DEFAULT 'weekly'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_settings_backup_frequency_check CHECK ((backup_frequency = ANY (ARRAY['daily'::text, 'weekly'::text, 'monthly'::text]))),
    CONSTRAINT user_settings_default_view_check CHECK ((default_view = ANY (ARRAY['grid'::text, 'list'::text, 'tree'::text]))),
    CONSTRAINT user_settings_theme_check CHECK ((theme = ANY (ARRAY['light'::text, 'dark'::text, 'system'::text])))
);


ALTER TABLE public.user_settings OWNER TO postgres;

--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: backups backups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_pkey PRIMARY KEY (id);


--
-- Name: bookmark_tags bookmark_tags_bookmark_id_tag_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmark_tags
    ADD CONSTRAINT bookmark_tags_bookmark_id_tag_id_key UNIQUE (bookmark_id, tag_id);


--
-- Name: bookmark_tags bookmark_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmark_tags
    ADD CONSTRAINT bookmark_tags_pkey PRIMARY KEY (id);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: tags tags_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_name_key UNIQUE (name);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (id);


--
-- Name: user_settings user_settings_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_user_id_key UNIQUE (user_id);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_created_at ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_log_user_id ON public.audit_log USING btree (user_id);


--
-- Name: idx_bookmark_tags_bookmark_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmark_tags_bookmark_id ON public.bookmark_tags USING btree (bookmark_id);


--
-- Name: idx_bookmark_tags_tag_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmark_tags_tag_id ON public.bookmark_tags USING btree (tag_id);


--
-- Name: idx_bookmarks_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmarks_created_at ON public.bookmarks USING btree (created_at);


--
-- Name: idx_bookmarks_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmarks_parent_id ON public.bookmarks USING btree (parent_id);


--
-- Name: idx_bookmarks_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmarks_type ON public.bookmarks USING btree (type);


--
-- Name: idx_bookmarks_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmarks_user_id ON public.bookmarks USING btree (user_id);


--
-- Name: idx_tags_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tags_name ON public.tags USING btree (name);


--
-- Name: bookmarks audit_bookmark_changes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_bookmark_changes AFTER INSERT OR DELETE OR UPDATE ON public.bookmarks FOR EACH ROW EXECUTE FUNCTION public.log_bookmark_changes();


--
-- Name: bookmarks update_bookmarks_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_bookmarks_updated_at BEFORE UPDATE ON public.bookmarks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: profiles update_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_settings update_user_settings_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: backups backups_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: bookmark_tags bookmark_tags_bookmark_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmark_tags
    ADD CONSTRAINT bookmark_tags_bookmark_id_fkey FOREIGN KEY (bookmark_id) REFERENCES public.bookmarks(id) ON DELETE CASCADE;


--
-- Name: bookmark_tags bookmark_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmark_tags
    ADD CONSTRAINT bookmark_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: bookmarks bookmarks_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.bookmarks(id) ON DELETE CASCADE;


--
-- Name: bookmarks bookmarks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: tags tags_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: user_settings user_settings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles Usuários podem atualizar seu próprio perfil; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: bookmarks Usuários podem atualizar seus próprios favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem atualizar seus próprios favoritos" ON public.bookmarks FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_settings Usuários podem atualizar suas próprias configurações; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem atualizar suas próprias configurações" ON public.user_settings FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: tags Usuários podem atualizar tags que criaram; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem atualizar tags que criaram" ON public.tags FOR UPDATE TO authenticated USING ((created_by = auth.uid()));


--
-- Name: backups Usuários podem criar seus próprios backups; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem criar seus próprios backups" ON public.backups FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: bookmarks Usuários podem criar seus próprios favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem criar seus próprios favoritos" ON public.bookmarks FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_settings Usuários podem criar suas próprias configurações; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem criar suas próprias configurações" ON public.user_settings FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: tags Usuários podem criar suas próprias tags; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem criar suas próprias tags" ON public.tags FOR INSERT TO authenticated WITH CHECK ((created_by = auth.uid()));


--
-- Name: bookmark_tags Usuários podem criar tags para seus favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem criar tags para seus favoritos" ON public.bookmark_tags FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.bookmarks
  WHERE ((bookmarks.id = bookmark_tags.bookmark_id) AND (bookmarks.user_id = auth.uid())))));


--
-- Name: bookmarks Usuários podem deletar seus próprios favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem deletar seus próprios favoritos" ON public.bookmarks FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: bookmark_tags Usuários podem deletar tags dos seus favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem deletar tags dos seus favoritos" ON public.bookmark_tags FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.bookmarks
  WHERE ((bookmarks.id = bookmark_tags.bookmark_id) AND (bookmarks.user_id = auth.uid())))));


--
-- Name: tags Usuários podem deletar tags que criaram; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem deletar tags que criaram" ON public.tags FOR DELETE TO authenticated USING ((created_by = auth.uid()));


--
-- Name: profiles Usuários podem inserir seu próprio perfil; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem inserir seu próprio perfil" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: profiles Usuários podem ver seu próprio perfil; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver seu próprio perfil" ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: backups Usuários podem ver seus próprios backups; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver seus próprios backups" ON public.backups FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: bookmarks Usuários podem ver seus próprios favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver seus próprios favoritos" ON public.bookmarks FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: audit_log Usuários podem ver seus próprios logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver seus próprios logs" ON public.audit_log FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_settings Usuários podem ver suas próprias configurações; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver suas próprias configurações" ON public.user_settings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: bookmark_tags Usuários podem ver tags dos seus favoritos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver tags dos seus favoritos" ON public.bookmark_tags FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.bookmarks
  WHERE ((bookmarks.id = bookmark_tags.bookmark_id) AND (bookmarks.user_id = auth.uid())))));


--
-- Name: tags Usuários podem ver tags públicas ou que criaram; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuários podem ver tags públicas ou que criaram" ON public.tags FOR SELECT TO authenticated USING (((is_shared = true) OR (created_by = auth.uid())));


--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: backups; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.backups ENABLE ROW LEVEL SECURITY;

--
-- Name: bookmark_tags; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.bookmark_tags ENABLE ROW LEVEL SECURITY;

--
-- Name: bookmarks; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: tags; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;

--
-- Name: user_settings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION get_user_stats(user_uuid uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_user_stats(user_uuid uuid) TO anon;
GRANT ALL ON FUNCTION public.get_user_stats(user_uuid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_stats(user_uuid uuid) TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION log_bookmark_changes(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.log_bookmark_changes() TO anon;
GRANT ALL ON FUNCTION public.log_bookmark_changes() TO authenticated;
GRANT ALL ON FUNCTION public.log_bookmark_changes() TO service_role;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;


--
-- Name: TABLE audit_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.audit_log TO anon;
GRANT ALL ON TABLE public.audit_log TO authenticated;
GRANT ALL ON TABLE public.audit_log TO service_role;


--
-- Name: TABLE backups; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.backups TO anon;
GRANT ALL ON TABLE public.backups TO authenticated;
GRANT ALL ON TABLE public.backups TO service_role;


--
-- Name: TABLE bookmark_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.bookmark_tags TO anon;
GRANT ALL ON TABLE public.bookmark_tags TO authenticated;
GRANT ALL ON TABLE public.bookmark_tags TO service_role;


--
-- Name: TABLE bookmarks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.bookmarks TO anon;
GRANT ALL ON TABLE public.bookmarks TO authenticated;
GRANT ALL ON TABLE public.bookmarks TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.tags TO anon;
GRANT ALL ON TABLE public.tags TO authenticated;
GRANT ALL ON TABLE public.tags TO service_role;


--
-- Name: TABLE user_settings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_settings TO anon;
GRANT ALL ON TABLE public.user_settings TO authenticated;
GRANT ALL ON TABLE public.user_settings TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- PostgreSQL database dump complete
--

