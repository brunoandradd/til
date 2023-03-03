--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3
-- Dumped by pg_dump version 14.6 (Ubuntu 14.6-0ubuntu0.22.04.1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ads (
    id integer NOT NULL,
    image_url character varying NOT NULL,
    link_url character varying NOT NULL,
    clicks integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mobile_image_url character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ads_id_seq OWNED BY public.ads.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channels (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    twitter_hashtag character varying(20) NOT NULL,
    CONSTRAINT twitter_hashtag_alphanumeric_constraint CHECK (((twitter_hashtag)::text ~ '^[\w\d]+$'::text))
);


--
-- Name: channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.channels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.channels_id_seq OWNED BY public.channels.id;


--
-- Name: developers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.developers (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    username character varying NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    twitter_handle character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    editor character varying DEFAULT 'Text Field'::character varying,
    slack_name character varying
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id integer NOT NULL,
    developer_id integer NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    channel_id integer NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    likes integer DEFAULT 1 NOT NULL,
    tweeted boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    max_likes integer DEFAULT 1 NOT NULL,
    CONSTRAINT likes CHECK ((likes >= 0))
);


--
-- Name: hot_posts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.hot_posts AS
 WITH posts_with_age AS (
         SELECT posts.id,
            posts.developer_id,
            posts.body,
            posts.created_at,
            posts.updated_at,
            posts.channel_id,
            posts.title,
            posts.slug,
            posts.likes,
            posts.tweeted,
            posts.published_at,
            GREATEST((date_part('epoch'::text, (CURRENT_TIMESTAMP - posts.published_at)) / (3600)::double precision), (0.1)::double precision) AS hour_age
           FROM public.posts
          WHERE (posts.published_at IS NOT NULL)
        )
 SELECT ((posts_with_age.likes)::double precision / (posts_with_age.hour_age ^ (0.8)::double precision)) AS score,
    posts_with_age.id,
    posts_with_age.developer_id,
    posts_with_age.body,
    posts_with_age.created_at,
    posts_with_age.updated_at,
    posts_with_age.channel_id,
    posts_with_age.title,
    posts_with_age.slug,
    posts_with_age.likes,
    posts_with_age.tweeted,
    posts_with_age.published_at,
    posts_with_age.hour_age
   FROM posts_with_age
  ORDER BY ((posts_with_age.likes)::double precision / (posts_with_age.hour_age ^ (0.8)::double precision)) DESC;


--
-- Name: developer_scores; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.developer_scores AS
 SELECT developers.id,
    developers.username,
    stats.posts,
    stats.likes,
    round(((stats.likes)::numeric / (stats.posts)::numeric), 2) AS avg_likes,
    round(log((2)::numeric, ((((1022)::double precision * ((developer_scores.score - min(developer_scores.score) OVER ()) / (max(developer_scores.score) OVER () - min(developer_scores.score) OVER ()))) + (2)::double precision))::numeric), 1) AS hotness
   FROM ((public.developers
     JOIN ( SELECT hot_posts.developer_id AS id,
            sum(hot_posts.score) AS score
           FROM public.hot_posts
          GROUP BY hot_posts.developer_id) developer_scores USING (id))
     JOIN ( SELECT posts.developer_id AS id,
            count(*) AS posts,
            sum(posts.likes) AS likes
           FROM public.posts
          GROUP BY posts.developer_id) stats USING (id));


--
-- Name: developers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.developers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: developers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.developers_id_seq OWNED BY public.developers.id;


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads ALTER COLUMN id SET DEFAULT nextval('public.ads_id_seq'::regclass);


--
-- Name: channels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channels ALTER COLUMN id SET DEFAULT nextval('public.channels_id_seq'::regclass);


--
-- Name: developers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developers ALTER COLUMN id SET DEFAULT nextval('public.developers_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: ads ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: developers developers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: posts unique_slug; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT unique_slug UNIQUE (slug);


--
-- Name: index_developers_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_developers_on_email ON public.developers USING btree (email);


--
-- Name: index_posts_on_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_channel_id ON public.posts USING btree (channel_id);


--
-- Name: index_posts_on_developer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_developer_id ON public.posts USING btree (developer_id);


--
-- Name: posts fk_rails_06b7a0db99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_06b7a0db99 FOREIGN KEY (channel_id) REFERENCES public.channels(id);


--
-- Name: posts fk_rails_2c578d8f8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_rails_2c578d8f8f FOREIGN KEY (developer_id) REFERENCES public.developers(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20140125153715'),
('20150317204546'),
('20150319202107'),
('20150319204402'),
('20150324163219'),
('20150414002719'),
('20150529183728'),
('20150529190148'),
('20150601191337'),
('20150603155844'),
('20150610141445'),
('20150610145829'),
('20150825183004'),
('20150903191744'),
('20150922171442'),
('20150925155814'),
('20151001212705'),
('20160115214137'),
('20160115214650'),
('20160125205238'),
('20160205153837'),
('20160211043316'),
('20160223002123'),
('20160622144602'),
('20160622152349'),
('20160622154534'),
('20160701161129'),
('20160708201736'),
('20210202151545'),
('20210206213709'),
('20210212181919'),
('20210224230319');


