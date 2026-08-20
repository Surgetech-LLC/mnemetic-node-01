--
-- PostgreSQL database dump
--

\restrict Ip4txf2IJfocpxVe2bIPiaZspRHU6K6GUIj0eoJWFFtPGoeDGVygfm41ARU0z36

-- Dumped from database version 18.4 (Debian 18.4-1.pgdg12+1)
-- Dumped by pg_dump version 18.4 (Debian 18.4-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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
-- Name: lab_validation; Type: TABLE; Schema: public; Owner: mnemetic
--

CREATE TABLE public.lab_validation (
    id bigint NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.lab_validation OWNER TO mnemetic;

--
-- Name: lab_validation_id_seq; Type: SEQUENCE; Schema: public; Owner: mnemetic
--

CREATE SEQUENCE public.lab_validation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lab_validation_id_seq OWNER TO mnemetic;

--
-- Name: lab_validation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mnemetic
--

ALTER SEQUENCE public.lab_validation_id_seq OWNED BY public.lab_validation.id;


--
-- Name: lab_validation id; Type: DEFAULT; Schema: public; Owner: mnemetic
--

ALTER TABLE ONLY public.lab_validation ALTER COLUMN id SET DEFAULT nextval('public.lab_validation_id_seq'::regclass);


--
-- Data for Name: lab_validation; Type: TABLE DATA; Schema: public; Owner: mnemetic
--

COPY public.lab_validation (id, note, created_at) FROM stdin;
1	Mnemetic Node 01 persistence test	2026-08-20 14:45:17.33715+00
\.


--
-- Name: lab_validation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mnemetic
--

SELECT pg_catalog.setval('public.lab_validation_id_seq', 1, true);


--
-- Name: lab_validation lab_validation_pkey; Type: CONSTRAINT; Schema: public; Owner: mnemetic
--

ALTER TABLE ONLY public.lab_validation
    ADD CONSTRAINT lab_validation_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

\unrestrict Ip4txf2IJfocpxVe2bIPiaZspRHU6K6GUIj0eoJWFFtPGoeDGVygfm41ARU0z36

