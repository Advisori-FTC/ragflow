-- PostgreSQL initialization script for RAGFlow
-- This script is automatically executed when the PostgreSQL container starts for the first time

-- Database is already created via POSTGRES_DB environment variable
-- Just ensure we're connected to the right database
\c rag_flow;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Set default encoding and locale
SET client_encoding = 'UTF8';

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON DATABASE rag_flow TO rag_flow;
GRANT ALL PRIVILEGES ON SCHEMA public TO rag_flow;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO rag_flow;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO rag_flow;
