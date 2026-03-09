/*
 * =============================================================================
 * Nexus Team — RBAC Implementation
 * Intuitive Surgical — Cortex Agent Development & Cross-Functional Data Access
 * =============================================================================
 *
 * Prerequisites:
 *   - Execute as ACCOUNTADMIN (or USERADMIN for role creation, SYSADMIN for objects)
 *   - Functional RO roles (e.g., MANUFACTURING_RO) must already exist
 *   - Replace <FUNCTIONAL_RO> placeholders with actual role names
 *
 * Sections:
 *   1. Custom Roles
 *   2. Role Hierarchy
 *   3. Database & Schemas
 *   4. Warehouse
 *   5. Cortex Database Roles
 *   6. Schema-Level Privileges for NEXUS_AGENT_ADMIN
 *   7. Functional RO Role Grants (inbound — data read)
 *   8. Agent Access Grants (outbound — agent usage to functional roles)
 */

-- =============================================================================
-- 1. CUSTOM ROLES
-- =============================================================================

USE ROLE USERADMIN;

CREATE ROLE IF NOT EXISTS NEXUS_ADMIN
    COMMENT = 'Top-level Nexus team role. Owns NEXUS_DB and manages role grants.';

CREATE ROLE IF NOT EXISTS NEXUS_AGENT_ADMIN
    COMMENT = 'Operational role for creating/managing Cortex Agents, Search Services, and Semantic Views. Inherits RO data access. Grants agent usage to functional roles.';

-- =============================================================================
-- 2. ROLE HIERARCHY
-- =============================================================================

-- NEXUS_AGENT_ADMIN → NEXUS_ADMIN → SYSADMIN
GRANT ROLE NEXUS_AGENT_ADMIN TO ROLE NEXUS_ADMIN;
GRANT ROLE NEXUS_ADMIN TO ROLE SYSADMIN;

-- =============================================================================
-- 3. DATABASE & SCHEMAS
-- =============================================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS NEXUS_DB
    COMMENT = 'Dedicated database for Nexus team Cortex Agent development';

-- Transfer ownership to NEXUS_ADMIN
GRANT OWNERSHIP ON DATABASE NEXUS_DB TO ROLE NEXUS_ADMIN COPY CURRENT GRANTS;

USE ROLE NEXUS_ADMIN;
USE DATABASE NEXUS_DB;

CREATE SCHEMA IF NOT EXISTS NEXUS_DB.AGENTS
    COMMENT = 'Cortex Agent objects';

CREATE SCHEMA IF NOT EXISTS NEXUS_DB.SEARCH_SERVICES
    COMMENT = 'Cortex Search Service indexes';

CREATE SCHEMA IF NOT EXISTS NEXUS_DB.SEMANTIC_VIEWS
    COMMENT = 'Semantic Views for Cortex Analyst';

CREATE SCHEMA IF NOT EXISTS NEXUS_DB.STAGING
    COMMENT = 'Raw and intermediate data for agent development';

CREATE SCHEMA IF NOT EXISTS NEXUS_DB.MODELS
    COMMENT = 'YAML agent specification files and stages';

-- =============================================================================
-- 4. WAREHOUSE
-- =============================================================================

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS NEXUS_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated warehouse for Nexus team agent operations';

GRANT USAGE ON WAREHOUSE NEXUS_WH TO ROLE NEXUS_AGENT_ADMIN;
GRANT OPERATE ON WAREHOUSE NEXUS_WH TO ROLE NEXUS_AGENT_ADMIN;

-- =============================================================================
-- 5. CORTEX DATABASE ROLES
-- =============================================================================

USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE NEXUS_AGENT_ADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE NEXUS_AGENT_ADMIN;

-- =============================================================================
-- 6. SCHEMA-LEVEL PRIVILEGES FOR NEXUS_AGENT_ADMIN
-- =============================================================================

USE ROLE NEXUS_ADMIN;

-- Full usage on all schemas
GRANT USAGE ON ALL SCHEMAS IN DATABASE NEXUS_DB TO ROLE NEXUS_AGENT_ADMIN;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE NEXUS_DB TO ROLE NEXUS_AGENT_ADMIN;

-- AGENTS schema: create agents
GRANT CREATE AGENT ON SCHEMA NEXUS_DB.AGENTS TO ROLE NEXUS_AGENT_ADMIN;

-- SEARCH_SERVICES schema: create cortex search services
GRANT CREATE CORTEX SEARCH SERVICE ON SCHEMA NEXUS_DB.SEARCH_SERVICES TO ROLE NEXUS_AGENT_ADMIN;

-- SEMANTIC_VIEWS schema: create semantic views
GRANT CREATE SEMANTIC VIEW ON SCHEMA NEXUS_DB.SEMANTIC_VIEWS TO ROLE NEXUS_AGENT_ADMIN;

-- STAGING schema: create tables and stages for data prep
GRANT CREATE TABLE ON SCHEMA NEXUS_DB.STAGING TO ROLE NEXUS_AGENT_ADMIN;
GRANT CREATE STAGE ON SCHEMA NEXUS_DB.STAGING TO ROLE NEXUS_AGENT_ADMIN;

-- MODELS schema: create stages for YAML specs
GRANT CREATE STAGE ON SCHEMA NEXUS_DB.MODELS TO ROLE NEXUS_AGENT_ADMIN;

-- =============================================================================
-- 7. FUNCTIONAL RO ROLE GRANTS (INBOUND — DATA READ)
--    Grant existing functional RO roles INTO NEXUS_AGENT_ADMIN so it inherits
--    SELECT on source tables across business function databases.
--
--    *** REPLACE placeholders with actual customer role names ***
-- =============================================================================

USE ROLE USERADMIN;

-- GRANT ROLE MANUFACTURING_RO TO ROLE NEXUS_AGENT_ADMIN;
-- GRANT ROLE FIELD_SERVICES_RO TO ROLE NEXUS_AGENT_ADMIN;
-- GRANT ROLE HR_RO TO ROLE NEXUS_AGENT_ADMIN;
-- GRANT ROLE FINANCE_RO TO ROLE NEXUS_AGENT_ADMIN;
-- GRANT ROLE SUPPLY_CHAIN_RO TO ROLE NEXUS_AGENT_ADMIN;
-- GRANT ROLE QUALITY_RO TO ROLE NEXUS_AGENT_ADMIN;

-- =============================================================================
-- 8. AGENT ACCESS GRANTS (OUTBOUND — AGENT USAGE TO FUNCTIONAL ROLES)
--    After NEXUS_AGENT_ADMIN creates an agent, run these grants so functional
--    teams can query it. Three levels are required: database, schema, object.
--
--    *** REPLACE placeholders with actual role and agent names ***
--    *** Run as NEXUS_AGENT_ADMIN (or NEXUS_ADMIN) after agent creation ***
-- =============================================================================

-- USE ROLE NEXUS_AGENT_ADMIN;

-- Example: grant <my_agent> to MANUFACTURING_RO
-- GRANT USAGE ON DATABASE NEXUS_DB TO ROLE MANUFACTURING_RO;
-- GRANT USAGE ON SCHEMA NEXUS_DB.AGENTS TO ROLE MANUFACTURING_RO;
-- GRANT USAGE ON AGENT NEXUS_DB.AGENTS.<my_agent> TO ROLE MANUFACTURING_RO;

-- Example: grant <my_agent> to FINANCE_RO
-- GRANT USAGE ON DATABASE NEXUS_DB TO ROLE FINANCE_RO;
-- GRANT USAGE ON SCHEMA NEXUS_DB.AGENTS TO ROLE FINANCE_RO;
-- GRANT USAGE ON AGENT NEXUS_DB.AGENTS.<my_agent> TO ROLE FINANCE_RO;

-- Repeat for each functional RO role that needs agent access.
-- The database and schema grants only need to be run once per role.
-- The agent-level grant is needed for each new agent.

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Check role hierarchy
-- SHOW GRANTS OF ROLE NEXUS_AGENT_ADMIN;
-- SHOW GRANTS OF ROLE NEXUS_ADMIN;

-- Check privileges on NEXUS_DB
-- SHOW GRANTS ON DATABASE NEXUS_DB;

-- Check schema privileges
-- SHOW GRANTS ON SCHEMA NEXUS_DB.AGENTS;
-- SHOW GRANTS ON SCHEMA NEXUS_DB.SEARCH_SERVICES;

-- Check Cortex database roles
-- SHOW GRANTS OF DATABASE ROLE SNOWFLAKE.CORTEX_USER;
-- SHOW GRANTS OF DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER;
