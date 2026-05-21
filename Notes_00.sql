-- =============================================================================
-- LECTURE 00 - OVERVIEW
-- Course  : Data Science & SQL Bootcamp
-- Date    : 12 May 2026
-- Topic   : Comprehensive Data Pipeline and AI Roles Overview
-- Note    : This is the intro/overview session before hands-on SQL begins
-- =============================================================================


-- =============================================================================
-- 1. WHAT IS DATA?
-- =============================================================================
-- Everything starts with one simple four-letter word: DATA
-- Raw data on its own means nothing. The goal is to convert data into
-- INFORMATION - something that tells a story and drives decisions.
--
-- Example:
--   Raw data  -> 100, John, 85
--   Information -> "John scored 85 marks in Math out of 100"
--
-- All roles in the data ecosystem exist because of this single need:
-- making sense of data.


-- =============================================================================
-- 2. TYPES OF DATA
-- =============================================================================

-- 2.1 STRUCTURED DATA
--   - Organised in rows and columns (tabular format)
--   - Has a predefined schema/template
--   - Easy to store, search, and query
--   - Stored in relational databases
--   - Examples: customer records, sales data, employee info
--   - Tools: MySQL, PostgreSQL, SQL Server, Snowflake

-- 2.2 SEMI-STRUCTURED DATA
--   - Not fully tabular but has labels/markers to organise it
--   - Uses key-value pairs instead of rows and columns
--   - Example (JSON format):
--       { "name": "John", "role": "data scientist" }
--   - Tools: MongoDB, Cassandra

-- 2.3 UNSTRUCTURED DATA
--   - No predefined format or organisation
--   - Cannot be put into a table directly
--   - Examples: images, videos, audio files, Word documents, emails
--   - Stored in: file storage, Azure Blob Storage, AWS S3 (Data Lakes)


-- =============================================================================
-- 3. DATA STORAGE TYPES
-- =============================================================================

-- 3.1 DATABASES (structured)
--   - Relational: MySQL, PostgreSQL, SQL Server
--   - NoSQL (semi-structured): MongoDB, Cassandra

-- 3.2 DATA WAREHOUSE
--   - Stores historical, processed, structured data
--   - Used for analytics and reporting
--   - Organised into FACTS and DIMENSIONS
--       * FACTS   -> quantitative/measurable data (sales amount, units sold)
--       * DIMENSIONS -> descriptive context (date, product, customer, location)
--   - Tools: Snowflake, BigQuery, Redshift, Greenplum

-- 3.3 DATA MART
--   - A sub-part / subset of the data warehouse
--   - Stores department-specific data
--   - Example: HR data mart, Finance data mart, Marketing data mart
--   - Purpose: apply business rules and analysis per department

-- 3.4 DATA LAKE
--   - Stores ALL types of data: structured, semi-structured, unstructured
--   - Holds raw files as they come in
--   - Tools: AWS S3, Azure Blob Storage

-- 3.5 BRONZE / SILVER / GOLD LAYERS (Data Lake Architecture)
--   - BRONZE  -> raw data as-is from source. Single source of truth. Never modified.
--   - SILVER  -> cleaned and processed data. Nulls handled, columns renamed, formatted.
--   - GOLD    -> final business-ready data. Business logic applied. Fed to dashboards,
--                ML models, or chatbots.


-- =============================================================================
-- 4. DATA PIPELINE & LIFECYCLE
-- =============================================================================
-- The journey data takes from source to consumption:
--
--   [Source] -> [Ingestion] -> [Processing/Cleaning] -> [Storage] -> [Analysis] -> [Consumption]
--
-- Step 1 - DATA COLLECTION / SOURCE
--   Where data originates. Types of sources:
--   - Databases     : PostgreSQL, MySQL, MongoDB
--   - APIs          : REST APIs, Google Maps, payment gateways
--   - Files         : CSV, JSON, XML, Word documents
--   - Event Streams : Kafka (real-time/live data)
--   - Web Scraping  : extracting data from websites
--   - IoT Devices   : wearables (Apple Watch), sensors tracking steps, sleep, calories
--
-- Step 2 - DATA INGESTION
--   Moving data from source into centralised storage. Two types:
--   - REAL-TIME (Stream): data processed instantly as it arrives
--       Example: UPI/PhonePe transaction updates within seconds
--       Tools: Apache Kafka, Apache NiFi, Flume
--   - BATCH: data collected over a period then processed all at once
--       Example: processing last 24 hours of log files together
--       Tools: Apache Spark, Apache Flink
--
-- Step 3 - DATA PROCESSING / TRANSFORMATION
--   Cleaning and preparing data:
--   - Handle missing values and nulls
--   - Rename columns, standardise formats
--   - Apply business logic and rules
--   - ETL  (Extract -> Transform -> Load): transform before storing. Best for on-prem.
--   - ELT  (Extract -> Load -> Transform): load raw first, transform in cloud.
--       Best for massive data volumes in cloud environments.
--   - Tools: Apache Spark, Hadoop (MapReduce), dbt, Azure Synapse, BigQuery, Snowflake
--
-- Step 4 - DATA STORAGE
--   (see Section 3 above)
--
-- Step 5 - ANALYSIS & CONSUMPTION
--   - Dashboards & BI: Power BI, Tableau
--   - Python visualisation: matplotlib, plotly, cufflinks
--   - Machine Learning models, chatbots, reports
--   - KPIs and DAX measures for business metrics


-- =============================================================================
-- 5. ETL vs ELT
-- =============================================================================
-- ETL (Extract, Transform, Load)
--   - Extract data from source
--   - Transform/clean it externally
--   - Load clean data into destination
--   - Best for: on-premise, complex transformation logic, small/medium datasets
--
-- ELT (Extract, Load, Transform)
--   - Extract data from source
--   - Load raw data directly into cloud storage
--   - Transform it inside the cloud platform
--   - Best for: cloud-native, massive data volumes, faster and cheaper
--   - Tools: dbt, Azure Synapse, Azure Data Factory (ADF), BigQuery, Snowflake


-- =============================================================================
-- 6. BIG DATA PROCESSING
-- =============================================================================
-- When data grows to millions/hundreds of millions of records,
-- standard databases are not enough. Big data tools are needed.
--
-- HADOOP
--   - Uses HDFS (Hadoop Distributed File System) for storage across machines
--   - Processes using MapReduce: breaks tasks into chunks, processes in parallel
--   - Good for batch processing
--   - Limitation: serial/slow in some scenarios
--
-- APACHE SPARK
--   - Uses in-memory parallel processing - much faster than Hadoop MapReduce
--   - Sits on top of HDFS
--   - Supports both batch AND real-time stream processing
--   - Used by Snowflake, BigQuery and most modern cloud platforms behind the scenes
--   - Best for: heavy transformation, data cleaning, pre-processing at scale


-- =============================================================================
-- 7. ORCHESTRATION
-- =============================================================================
-- Orchestration = managing and coordinating the entire pipeline end-to-end
-- Think of it like a music conductor directing all musicians in sequence
--
-- Responsibilities of orchestration:
--   - Which pipeline runs at what time (scheduling)
--   - Error handling and logging
--   - Debugging failed jobs
--   - Ensuring sequential and dependency-based execution
--
-- Tools:
--   - Apache Airflow (most popular standalone orchestration tool)
--   - Prefect, Dagster
--   - Cloud-native: Azure Data Factory (ADF), AWS Glue (inbuilt orchestration)
--   - Cloud platforms now bundle orchestration so you don't need separate tools


-- =============================================================================
-- 8. ROLES IN THE DATA ECOSYSTEM
-- =============================================================================

-- DATA ENGINEER
--   - Builds and maintains ETL/ELT pipelines
--   - Designs data warehouses and data marts
--   - Handles data ingestion (real-time and batch)
--   - Manages Bronze/Silver/Gold data layers
--   - Sets up cloud storage and orchestration
--   - Tools: Spark, Kafka, Airflow, ADF, Glue, SQL, Python

-- DATA ANALYST / BI ANALYST
--   - Consumes processed data from warehouses or data marts
--   - Builds dashboards, reports, visualisations
--   - Identifies business insights and trends
--   - Tools: Power BI, Tableau, SQL, DAX, Python (matplotlib, plotly)

-- DATA SCIENTIST
--   - Works with steps 5 and 6 of the lifecycle (analysis + ML)
--   - Builds machine learning and AI models
--   - Must understand the full pipeline to work effectively
--   - Core skills: Python, SQL, Statistics, ML frameworks

-- DATA GOVERNANCE
--   - Protects sensitive data (health, finance, personal info)
--   - Applies masking, encryption, and anonymisation
--   - Defines rules on who can see/access what data
--   - Tools: AWS Glue Data Catalog, Apache Atlas, Azure Purview

-- DATA QUALITY / QA TESTING
--   - Validates that pipelines and transformations are correct
--   - Unit testing, regression testing, production testing
--   - QA engineers test from a product/user perspective (not just developer view)

-- DEVOPS
--   - CI/CD pipelines for automating deployment of data pipelines
--   - Continuous Integration + Continuous Development

-- MLOPS
--   - CI/CD pipelines specifically for machine learning models
--   - Automating training, deployment, and monitoring of ML models


-- =============================================================================
-- 9. EVOLUTION OF DATA SCIENCE & AI
-- =============================================================================
-- The progression from simple statistics to modern AI:
--
-- STATISTICS
--   - Descriptive statistics: mean, median, mode, central tendency
--   - Inferential statistics: hypothesis testing, null hypothesis
--   - Probability, permutations, combinations
--   - Example: Testing if a vaccine works or doesn't (null hypothesis)
--
-- MACHINE LEARNING (ML)
--   - Machines learn patterns from data that humans can't process at scale
--   - Works with structured/categorical data
--   - Models: Linear Regression, Logistic Regression, Decision Trees,
--             Random Forest, Bagging, Boosting, Clustering, PCA
--   - Use cases: price prediction, fraud detection, spam classification,
--                cancer detection, stock price forecasting, weather forecasting
--
-- DEEP LEARNING / NEURAL NETWORKS
--   - Handles unstructured data (images, text)
--   - CNN (Convolutional Neural Network): image detection, classification
--   - ANN (Artificial Neural Network): general neural architectures
--
-- NATURAL LANGUAGE PROCESSING (NLP)
--   - Enables human-to-machine communication in natural language
--   - Machine understands, processes, and responds in English/other languages
--   - Intent identification, sentiment analysis
--
-- TRANSFORMER ARCHITECTURE & LLMs
--   - Transformer models led to Large Language Models (LLMs)
--   - LLMs: GPT, Claude, Gemini, BERT
--   - Text generation: machine creates responses, not just classifies
--
-- GENERATIVE AI
--   - Builds on LLMs for text generation
--   - Computer vision models for image generation: DALL-E, Diffusion models
--   - Current trend in the industry
--
-- RAG (Retrieval-Augmented Generation)
--   - Makes LLMs answer from YOUR specific documents instead of generic training
--   - Example: LLM that answers only from a company's mental health documents
--   - Frameworks: LangChain, LangGraph
--
-- AGENT AI (Current Trend)
--   - AI agents that connect to live web data and external tools
--   - Example: "What is the next flight from New York to Hyderabad?"
--   - Agent goes to the web, retrieves live data, gives LLM the answer
--   - Uses custom tools written by developers


-- =============================================================================
-- 10. CORE SKILLS REQUIRED (ANY DATA ROLE)
-- =============================================================================
-- Regardless of which data role you pick, these two are always asked:
--   1. SQL (Structured Query Language)  <- we start here
--   2. Python
--
-- Role-specific additional skills:
--
--   Data Pipelines / ETL:
--     - Apache Airflow, Spark, Kafka
--     - Azure Data Factory, AWS Glue, Informatica
--
--   Cloud Platforms:
--     - Azure, AWS, GCP
--
--   Databases (Structured):
--     - MySQL, PostgreSQL, SQL Server, Snowflake
--
--   Databases (Semi-structured / NoSQL):
--     - MongoDB, Cassandra
--
--   Data Storage:
--     - AWS S3, Azure Blob Storage (Data Lakes)
--
--   BI / Reporting:
--     - Power BI, Tableau
--     - Python: matplotlib, plotly, cufflinks


-- =============================================================================
-- 11. COURSE PLAN (7 WEEKS)
-- =============================================================================
-- Week 1 : SQL
-- Week 2 : Python
-- Week 3 : Statistics
-- Week 4 : Machine Learning
-- Week 5 : NLP (Natural Language Processing)
-- Week 6 : Transformers & LLMs
-- Week 7 : Generative AI & Prompt Engineering
--
-- Setup required before next class (Monday):
--   - MySQL Server     (download from official MySQL site)
--   - MySQL Workbench  (UI to interact with the server)
--   - Load the Circular/SKIL database provided by instructor
--   - If your existing MySQL 8.0 works, do NOT update it (risk of file corruption)
