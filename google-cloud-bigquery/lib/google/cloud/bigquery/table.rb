# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "google/cloud/errors"
require "google/cloud/bigquery/service"
require "google/cloud/bigquery/view"
require "google/cloud/bigquery/data"
require "google/cloud/bigquery/table/list"
require "google/cloud/bigquery/schema"
require "google/cloud/bigquery/external"
require "google/cloud/bigquery/insert_response"
require "google/cloud/bigquery/table/async_inserter"
require "google/apis/bigquery_v2"

module Google
  module Cloud
    module Bigquery
      ##
      # # Table
      #
      # A named resource representing a BigQuery table that holds zero or more
      # records. Every table is defined by a schema that may contain nested and
      # repeated fields.
      #
      # @see https://cloud.google.com/bigquery/preparing-data-for-bigquery
      #   Preparing Data for BigQuery
      #
      # @example
      #   require "google/cloud/bigquery"
      #
      #   bigquery = Google::Cloud::Bigquery.new
      #   dataset = bigquery.dataset "my_dataset"
      #
      #   table = dataset.create_table "my_table" do |schema|
      #     schema.string "first_name", mode: :required
      #     schema.record "cities_lived", mode: :repeated do |nested_schema|
      #       nested_schema.string "place", mode: :required
      #       nested_schema.integer "number_of_years", mode: :required
      #     end
      #   end
      #
      #   row = {
      #     "first_name" => "Alice",
      #     "cities_lived" => [
      #       {
      #         "place" => "Seattle",
      #         "number_of_years" => 5
      #       },
      #       {
      #         "place" => "Stockholm",
      #         "number_of_years" => 6
      #       }
      #     ]
      #   }
      #   table.insert row
      #
      class Table
        ##
        # @private The Service object.
        attr_accessor :service

        ##
        # @private The Google API Client object.
        attr_accessor :gapi

        ##
        # @private Create an empty Table object.
        def initialize
          @service = nil
          @gapi = Google::Apis::BigqueryV2::Table.new
        end

        ##
        # A unique ID for this table.
        #
        # @return [String] The ID must contain only letters (a-z, A-Z), numbers
        #   (0-9), or underscores (_). The maximum length is 1,024 characters.
        #
        # @!group Attributes
        #
        def table_id
          @gapi.table_reference.table_id
        end

        ##
        # The ID of the `Dataset` containing this table.
        #
        # @return [String] The ID must contain only letters (a-z, A-Z), numbers
        #   (0-9), or underscores (_). The maximum length is 1,024 characters.
        #
        # @!group Attributes
        #
        def dataset_id
          @gapi.table_reference.dataset_id
        end

        ##
        # The ID of the `Project` containing this table.
        #
        # @return [String] The project ID.
        #
        # @!group Attributes
        #
        def project_id
          @gapi.table_reference.project_id
        end

        ##
        # @private The gapi fragment containing the Project ID, Dataset ID, and
        # Table ID as a camel-cased hash.
        def table_ref
          table_ref = @gapi.table_reference
          table_ref = table_ref.to_hash if table_ref.respond_to? :to_hash
          table_ref
        end

        ###
        # Checks if the table is time-partitioned. See [Partitioned
        # Tables](https://cloud.google.com/bigquery/docs/partitioned-tables).
        #
        # @return [Boolean] `true` when the table is time-partitioned, `false`
        #   otherwise.
        #
        # @!group Attributes
        #
        def time_partitioning?
          !@gapi.time_partitioning.nil?
        end

        ###
        # The period for which the table is partitioned, if any. See
        # [Partitioned Tables](https://cloud.google.com/bigquery/docs/partitioned-tables).
        #
        # @return [String, nil] The partition type. Currently the only supported
        #   value is "DAY".
        #
        # @!group Attributes
        #
        def time_partitioning_type
          ensure_full_data!
          @gapi.time_partitioning.type if time_partitioning?
        end

        ##
        # Sets the partitioning for the table. See [Partitioned
        # Tables](https://cloud.google.com/bigquery/docs/partitioned-tables).
        #
        # You can only set partitioning when creating a table as in
        # the example below. BigQuery does not allow you to change partitioning
        # on an existing table.
        #
        # @param [String] type The partition type. Currently the only
        #   supported value is "DAY".
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.create_table "my_table" do |table|
        #     table.time_partitioning_type = "DAY"
        #   end
        #
        # @!group Attributes
        #
        def time_partitioning_type= type
          @gapi.time_partitioning ||=
              Google::Apis::BigqueryV2::TimePartitioning.new
          @gapi.time_partitioning.type = type
          patch_gapi! :time_partitioning
        end


        ###
        # The expiration for the table partitions, if any, in seconds. See
        # [Partitioned Tables](https://cloud.google.com/bigquery/docs/partitioned-tables).
        #
        # @return [Integer, nil] The expiration time, in seconds, for data in
        #   partitions.
        #
        # @!group Attributes
        #
        def time_partitioning_expiration
          ensure_full_data!
          @gapi.time_partitioning.expiration_ms / 1_000 if
              time_partitioning? &&
              !@gapi.time_partitioning.expiration_ms.nil?
        end

        ##
        # Sets the partition expiration for the table. See [Partitioned
        # Tables](https://cloud.google.com/bigquery/docs/partitioned-tables).
        # The table must also be partitioned.
        #
        # See {Table#time_partitioning_type=}.
        #
        # @param [Integer] expiration An expiration time, in seconds,
        #   for data in partitions.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.create_table "my_table" do |table|
        #     table.time_partitioning_type = "DAY"
        #     table.time_partitioning_expiration = 86_400
        #   end
        #
        # @!group Attributes
        #
        def time_partitioning_expiration= expiration
          @gapi.time_partitioning ||=
              Google::Apis::BigqueryV2::TimePartitioning.new
          @gapi.time_partitioning.expiration_ms = expiration * 1000
          patch_gapi! :time_partitioning
        end

        ##
        # The combined Project ID, Dataset ID, and Table ID for this table, in
        # the format specified by the [Legacy SQL Query
        # Reference](https://cloud.google.com/bigquery/query-reference#from):
        # `project_name:datasetId.tableId`. To use this value in queries see
        # {#query_id}.
        #
        # @return [String] The combined ID.
        #
        # @!group Attributes
        #
        def id
          @gapi.id
        end

        ##
        # The value returned by {#id}, wrapped in square brackets if the Project
        # ID contains dashes, as specified by the [Query
        # Reference](https://cloud.google.com/bigquery/query-reference#from).
        # Useful in queries.
        #
        # @param [Boolean] standard_sql Specifies whether to use BigQuery's
        #   [standard
        #   SQL](https://cloud.google.com/bigquery/docs/reference/standard-sql/)
        #   dialect. Optional. The default value is true.
        # @param [Boolean] legacy_sql Specifies whether to use BigQuery's
        #   [legacy
        #   SQL](https://cloud.google.com/bigquery/docs/reference/legacy-sql)
        #   dialect. Optional. The default value is false.
        #
        # @return [String] The appropriate table ID for use in queries,
        #   depending on SQL type.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   data = bigquery.query "SELECT first_name FROM #{table.query_id}"
        #
        # @!group Attributes
        #
        def query_id standard_sql: nil, legacy_sql: nil
          if Convert.resolve_legacy_sql standard_sql, legacy_sql
            "[#{id}]"
          else
            "`#{project_id}.#{dataset_id}.#{table_id}`"
          end
        end

        ##
        # The name of the table.
        #
        # @return [String] The friendly name.
        #
        # @!group Attributes
        #
        def name
          @gapi.friendly_name
        end

        ##
        # Updates the name of the table.
        #
        # @param [String] new_name The new friendly name.
        #
        # @!group Attributes
        #
        def name= new_name
          @gapi.update! friendly_name: new_name
          patch_gapi! :friendly_name
        end

        ##
        # The ETag hash of the table.
        #
        # @return [String] The ETag hash.
        #
        # @!group Attributes
        #
        def etag
          ensure_full_data!
          @gapi.etag
        end

        ##
        # A URL that can be used to access the table using the REST API.
        #
        # @return [String] A REST URL for the resource.
        #
        # @!group Attributes
        #
        def api_url
          ensure_full_data!
          @gapi.self_link
        end

        ##
        # A user-friendly description of the table.
        #
        # @return [String] The description.
        #
        # @!group Attributes
        #
        def description
          ensure_full_data!
          @gapi.description
        end

        ##
        # Updates the user-friendly description of the table.
        #
        # @param [String] new_description The new user-friendly description.
        #
        # @!group Attributes
        #
        def description= new_description
          @gapi.update! description: new_description
          patch_gapi! :description
        end

        ##
        # The number of bytes in the table.
        #
        # @return [Integer] The count of bytes in the table.
        #
        # @!group Data
        #
        def bytes_count
          ensure_full_data!
          begin
            Integer @gapi.num_bytes
          rescue
            nil
          end
        end

        ##
        # The number of rows in the table.
        #
        # @return [Integer] The count of rows in the table.
        #
        # @!group Data
        #
        def rows_count
          ensure_full_data!
          begin
            Integer @gapi.num_rows
          rescue
            nil
          end
        end

        ##
        # The time when this table was created.
        #
        # @return [Time, nil] The creation time.
        #
        # @!group Attributes
        #
        def created_at
          ensure_full_data!
          begin
            ::Time.at(Integer(@gapi.creation_time) / 1000.0)
          rescue
            nil
          end
        end

        ##
        # The time when this table expires.
        # If not present, the table will persist indefinitely.
        # Expired tables will be deleted and their storage reclaimed.
        #
        # @return [Time, nil] The expiration time.
        #
        # @!group Attributes
        #
        def expires_at
          ensure_full_data!
          begin
            ::Time.at(Integer(@gapi.expiration_time) / 1000.0)
          rescue
            nil
          end
        end

        ##
        # The date when this table was last modified.
        #
        # @return [Time, nil] The last modified time.
        #
        # @!group Attributes
        #
        def modified_at
          ensure_full_data!
          begin
            ::Time.at(Integer(@gapi.last_modified_time) / 1000.0)
          rescue
            nil
          end
        end

        ##
        # Checks if the table's type is "TABLE".
        #
        # @return [Boolean] `true` when the type is `TABLE`, `false` otherwise.
        #
        # @!group Attributes
        #
        def table?
          @gapi.type == "TABLE"
        end

        ##
        # Checks if the table's type is "VIEW".
        #
        # @return [Boolean] `true` when the type is `VIEW`, `false` otherwise.
        #
        # @!group Attributes
        #
        def view?
          @gapi.type == "VIEW"
        end

        ##
        # Checks if the table's type is "EXTERNAL".
        #
        # @return [Boolean] `true` when the type is `EXTERNAL`, `false`
        #   otherwise.
        #
        # @!group Attributes
        #
        def external?
          @gapi.type == "EXTERNAL"
        end

        ##
        # The geographic location where the table should reside. Possible
        # values include `EU` and `US`. The default value is `US`.
        #
        # @return [String] The location code.
        #
        # @!group Attributes
        #
        def location
          ensure_full_data!
          @gapi.location
        end

        ##
        # A hash of user-provided labels associated with this table. Labels
        # are used to organize and group tables. See [Using
        # Labels](https://cloud.google.com/bigquery/docs/labels).
        #
        # The returned hash is frozen and changes are not allowed. Use
        # {#labels=} to replace the entire hash.
        #
        # @return [Hash<String, String>] A hash containing key/value pairs.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   labels = table.labels
        #   labels["department"] #=> "shipping"
        #
        # @!group Attributes
        #
        def labels
          m = @gapi.labels
          m = m.to_h if m.respond_to? :to_h
          m.dup.freeze
        end

        ##
        # Updates the hash of user-provided labels associated with this table.
        # Labels are used to organize and group tables. See [Using
        # Labels](https://cloud.google.com/bigquery/docs/labels).
        #
        # @param [Hash<String, String>] labels A hash containing key/value
        #   pairs.
        #
        #   * Label keys and values can be no longer than 63 characters.
        #   * Label keys and values can contain only lowercase letters, numbers,
        #     underscores, hyphens, and international characters.
        #   * Label keys and values cannot exceed 128 bytes in size.
        #   * Label keys must begin with a letter.
        #   * Label keys must be unique within a table.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   table.labels = { "department" => "shipping" }
        #
        # @!group Attributes
        #
        def labels= labels
          @gapi.labels = labels
          patch_gapi! :labels
        end

        ##
        # Returns the table's schema. This method can also be used to set,
        # replace, or add to the schema by passing a block. See {Schema} for
        # available methods.
        #
        # @param [Boolean] replace Whether to replace the existing schema with
        #   the new schema. If `true`, the fields will replace the existing
        #   schema. If `false`, the fields will be added to the existing schema.
        #   When a table already contains data, schema changes must be additive.
        #   Thus, the default value is `false`.
        # @yield [schema] a block for setting the schema
        # @yieldparam [Schema] schema the object accepting the schema
        #
        # @return [Google::Cloud::Bigquery::Schema] A frozen schema object.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.create_table "my_table"
        #
        #   table.schema do |schema|
        #     schema.string "first_name", mode: :required
        #     schema.record "cities_lived", mode: :repeated do |nested_schema|
        #       nested_schema.string "place", mode: :required
        #       nested_schema.integer "number_of_years", mode: :required
        #     end
        #   end
        #
        # @!group Attributes
        #
        def schema replace: false
          ensure_full_data!
          schema_builder = Schema.from_gapi @gapi.schema
          if block_given?
            schema_builder = Schema.from_gapi if replace
            yield schema_builder
            if schema_builder.changed?
              @gapi.schema = schema_builder.to_gapi
              patch_gapi! :schema
            end
          end
          schema_builder.freeze
        end

        ##
        # The fields of the table, obtained from its schema.
        #
        # @return [Array<Schema::Field>] An array of field objects.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   table.fields.each do |field|
        #     puts field.name
        #   end
        #
        # @!group Attributes
        #
        def fields
          schema.fields
        end

        ##
        # The names of the columns in the table, obtained from its schema.
        #
        # @return [Array<Symbol>] An array of column names.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   table.headers.each do |header|
        #     puts header
        #   end
        #
        # @!group Attributes
        #
        def headers
          schema.headers
        end

        ##
        # The {External::DataSource} (or subclass) object that represents the
        # external data source that the table represents. Data can be queried
        # the table, even though the data is not stored in BigQuery. Instead of
        # loading or streaming the data, this object references the external
        # data source.
        #
        # Present only if the table represents an External Data Source. See
        # {#external?} and {External::DataSource}.
        #
        # @see https://cloud.google.com/bigquery/external-data-sources
        #   Querying External Data Sources
        #
        # @return [External::DataSource] The external data source.
        #
        #   @!group Attributes
        #
        def external
          return nil if @gapi.external_data_configuration.nil?
          External.from_gapi(@gapi.external_data_configuration).freeze
        end

        ##
        # Set the {External::DataSource} (or subclass) object that represents
        # the external data source that the table represents. Data can be
        # queried the table, even though the data is not stored in BigQuery.
        # Instead of loading or streaming the data, this object references the
        # external data source.
        #
        # Use only if the table represents an External Data Source. See
        # {#external?} and {External::DataSource}.
        #
        # @see https://cloud.google.com/bigquery/external-data-sources
        #   Querying External Data Sources
        #
        # @param [External::DataSource] external An external data source.
        #
        # @!group Attributes
        #
        def external= external
          @gapi.external_data_configuration = external.to_gapi
          patch_gapi! :external_data_configuration
        end

        ##
        # A lower-bound estimate of the number of bytes currently in this
        # table's streaming buffer, if one is present. This field will be absent
        # if the table is not being streamed to or if there is no data in the
        # streaming buffer.
        #
        # @return [Integer] The estimated number of bytes in the buffer.
        #
        # @!group Attributes
        #
        def buffer_bytes
          ensure_full_data!
          @gapi.streaming_buffer.estimated_bytes if @gapi.streaming_buffer
        end

        ##
        # A lower-bound estimate of the number of rows currently in this
        # table's streaming buffer, if one is present. This field will be absent
        # if the table is not being streamed to or if there is no data in the
        # streaming buffer.
        #
        # @return [Integer] The estimated number of rows in the buffer.
        #
        # @!group Attributes
        #
        def buffer_rows
          ensure_full_data!
          @gapi.streaming_buffer.estimated_rows if @gapi.streaming_buffer
        end

        ##
        # The time of the oldest entry currently in this table's streaming
        # buffer, if one is present. This field will be absent if the table is
        # not being streamed to or if there is no data in the streaming buffer.
        #
        # @return [Time, nil] The oldest entry time.
        #
        # @!group Attributes
        #
        def buffer_oldest_at
          ensure_full_data!
          return nil unless @gapi.streaming_buffer
          oldest_entry_time = @gapi.streaming_buffer.oldest_entry_time
          begin
            ::Time.at(Integer(oldest_entry_time) / 1000.0)
          rescue
            nil
          end
        end

        ##
        # Retrieves data from the table.
        #
        # @param [String] token Page token, returned by a previous call,
        #   identifying the result set.
        #
        # @param [Integer] max Maximum number of results to return.
        # @param [Integer] start Zero-based index of the starting row to read.
        #
        # @return [Google::Cloud::Bigquery::Data]
        #
        # @example Paginate rows of data: (See {Data#next})
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   data = table.data
        #   data.each do |row|
        #     puts row[:first_name]
        #   end
        #   if data.next?
        #     more_data = data.next if data.next?
        #   end
        #
        # @example Retrieve all rows of data: (See {Data#all})
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   data = table.data
        #   data.all do |row|
        #     puts row[:first_name]
        #   end
        #
        # @!group Data
        #
        def data token: nil, max: nil, start: nil
          ensure_service!
          options = { token: token, max: max, start: start }
          data_gapi = service.list_tabledata dataset_id, table_id, options
          Data.from_gapi data_gapi, gapi, service
        end

        ##
        # Copies the data from the table to another table using an asynchronous
        # method. In this method, a {CopyJob} is immediately returned. The
        # caller may poll the service by repeatedly calling {Job#reload!} and
        # {Job#done?} to detect when the job is done, or simply block until the
        # job is done by calling #{Job#wait_until_done!}. See also {#copy}.
        #
        # @param [Table, String] destination_table The destination for the
        #   copied data. This can also be a string identifier as specified by
        #   the [Query
        #   Reference](https://cloud.google.com/bigquery/query-reference#from):
        #   `project_name:datasetId.tableId`. This is useful for referencing
        #   tables in other projects and datasets.
        # @param [String] create Specifies whether the job is allowed to create
        #   new tables. The default value is `needed`.
        #
        #   The following values are supported:
        #
        #   * `needed` - Create the table if it does not exist.
        #   * `never` - The table must already exist. A 'notFound' error is
        #     raised if the table does not exist.
        # @param [String] write Specifies how to handle data already present in
        #   the destination table. The default value is `empty`.
        #
        #   The following values are supported:
        #
        #   * `truncate` - BigQuery overwrites the table data.
        #   * `append` - BigQuery appends the data to the table.
        #   * `empty` - An error will be returned if the destination table
        #     already contains data.
        # @param [String] job_id A user-defined ID for the copy job. The ID
        #   must contain only letters (a-z, A-Z), numbers (0-9), underscores
        #   (_), or dashes (-). The maximum length is 1,024 characters. If
        #   `job_id` is provided, then `prefix` will not be used.
        #
        #   See [Generating a job
        #   ID](https://cloud.google.com/bigquery/docs/managing-jobs#generate-jobid).
        # @param [String] prefix A string, usually human-readable, that will be
        #   prepended to a generated value to produce a unique job ID. For
        #   example, the prefix `daily_import_job_` can be given to generate a
        #   job ID such as `daily_import_job_12vEDtMQ0mbp1Mo5Z7mzAFQJZazh`. The
        #   prefix must contain only letters (a-z, A-Z), numbers (0-9),
        #   underscores (_), or dashes (-). The maximum length of the entire ID
        #   is 1,024 characters. If `job_id` is provided, then `prefix` will not
        #   be used.
        # @param [Hash] labels A hash of user-provided labels associated with
        #   the job. You can use these to organize and group your jobs. Label
        #   keys and values can be no longer than 63 characters, can only
        #   contain lowercase letters, numeric characters, underscores and
        #   dashes. International characters are allowed. Label values are
        #   optional. Label keys must start with a letter and each label in the
        #   list must have a different key.
        #
        # @return [Google::Cloud::Bigquery::CopyJob]
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #   destination_table = dataset.table "my_destination_table"
        #
        #   copy_job = table.copy_job destination_table
        #
        # @example Passing a string identifier for the destination table:
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   copy_job = table.copy_job "other-project:other_dataset.other_table"
        #
        # @!group Data
        #
        def copy_job destination_table, create: nil, write: nil, dryrun: nil,
                     job_id: nil, prefix: nil, labels: nil
          ensure_service!
          options = { create: create, write: write, dryrun: dryrun,
                      job_id: job_id, prefix: prefix, labels: labels }
          gapi = service.copy_table table_ref,
                                    get_table_ref(destination_table),
                                    options
          Job.from_gapi gapi, service
        end

        ##
        # Copies the data from the table to another table using a synchronous
        # method that blocks for a response. Timeouts and transient errors are
        # generally handled as needed to complete the job. See also
        # {#copy_job}.
        #
        # @param [Table, String] destination_table The destination for the
        #   copied data. This can also be a string identifier as specified by
        #   the [Query
        #   Reference](https://cloud.google.com/bigquery/query-reference#from):
        #   `project_name:datasetId.tableId`. This is useful for referencing
        #   tables in other projects and datasets.
        # @param [String] create Specifies whether the job is allowed to create
        #   new tables. The default value is `needed`.
        #
        #   The following values are supported:
        #
        #   * `needed` - Create the table if it does not exist.
        #   * `never` - The table must already exist. A 'notFound' error is
        #     raised if the table does not exist.
        # @param [String] write Specifies how to handle data already present in
        #   the destination table. The default value is `empty`.
        #
        #   The following values are supported:
        #
        #   * `truncate` - BigQuery overwrites the table data.
        #   * `append` - BigQuery appends the data to the table.
        #   * `empty` - An error will be returned if the destination table
        #     already contains data.
        #
        # @return [Boolean] Returns `true` if the copy operation succeeded.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #   destination_table = dataset.table "my_destination_table"
        #
        #   table.copy destination_table
        #
        # @example Passing a string identifier for the destination table:
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   table.copy "other-project:other_dataset.other_table"
        #
        # @!group Data
        #
        def copy destination_table, create: nil, write: nil
          job = copy_job destination_table, create: create, write: write
          job.wait_until_done!

          if job.failed?
            begin
              # raise to activate ruby exception cause handling
              fail job.gapi_error
            rescue => e
              # wrap Google::Apis::Error with Google::Cloud::Error
              raise Google::Cloud::Error.from_error(e)
            end
          end

          true
        end

        ##
        # Extracts the data from the table to a Google Cloud Storage file using
        # an asynchronous method. In this method, an {ExtractJob} is immediately
        # returned. The caller may poll the service by repeatedly calling
        # {Job#reload!} and {Job#done?} to detect when the job is done, or
        # simply block until the job is done by calling #{Job#wait_until_done!}.
        # See also {#extract}.
        #
        # @see https://cloud.google.com/bigquery/exporting-data-from-bigquery
        #   Exporting Data From BigQuery
        #
        # @param [Google::Cloud::Storage::File, String, Array<String>]
        #   extract_url The Google Storage file or file URI pattern(s) to which
        #   BigQuery should extract the table data.
        # @param [String] format The exported file format. The default value is
        #   `csv`.
        #
        #   The following values are supported:
        #
        #   * `csv` - CSV
        #   * `json` - [Newline-delimited JSON](http://jsonlines.org/)
        #   * `avro` - [Avro](http://avro.apache.org/)
        # @param [String] compression The compression type to use for exported
        #   files. Possible values include `GZIP` and `NONE`. The default value
        #   is `NONE`.
        # @param [String] delimiter Delimiter to use between fields in the
        #   exported data. Default is <code>,</code>.
        # @param [Boolean] header Whether to print out a header row in the
        #   results. Default is `true`.
        # @param [String] job_id A user-defined ID for the extract job. The ID
        #   must contain only letters (a-z, A-Z), numbers (0-9), underscores
        #   (_), or dashes (-). The maximum length is 1,024 characters. If
        #   `job_id` is provided, then `prefix` will not be used.
        #
        #   See [Generating a job
        #   ID](https://cloud.google.com/bigquery/docs/managing-jobs#generate-jobid).
        # @param [String] prefix A string, usually human-readable, that will be
        #   prepended to a generated value to produce a unique job ID. For
        #   example, the prefix `daily_import_job_` can be given to generate a
        #   job ID such as `daily_import_job_12vEDtMQ0mbp1Mo5Z7mzAFQJZazh`. The
        #   prefix must contain only letters (a-z, A-Z), numbers (0-9),
        #   underscores (_), or dashes (-). The maximum length of the entire ID
        #   is 1,024 characters. If `job_id` is provided, then `prefix` will not
        #   be used.
        # @param [Hash] labels A hash of user-provided labels associated with
        #   the job. You can use these to organize and group your jobs. Label
        #   keys and values can be no longer than 63 characters, can only
        #   contain lowercase letters, numeric characters, underscores and
        #   dashes. International characters are allowed. Label values are
        #   optional. Label keys must start with a letter and each label in the
        #   list must have a different key.
        #
        #
        # @return [Google::Cloud::Bigquery::ExtractJob]
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   extract_job = table.extract_job "gs://my-bucket/file-name.json",
        #                               format: "json"
        #
        # @!group Data
        #
        def extract_job extract_url, format: nil, compression: nil,
                        delimiter: nil, header: nil, dryrun: nil, job_id: nil,
                        prefix: nil, labels: nil
          ensure_service!
          options = { format: format, compression: compression,
                      delimiter: delimiter, header: header, dryrun: dryrun,
                      job_id: job_id, prefix: prefix, labels: labels }
          gapi = service.extract_table table_ref, extract_url, options
          Job.from_gapi gapi, service
        end

        ##
        # Extracts the data from the table to a Google Cloud Storage file using
        # a synchronous method that blocks for a response. Timeouts and
        # transient errors are generally handled as needed to complete the job.
        # See also {#extract_job}.
        #
        # @see https://cloud.google.com/bigquery/exporting-data-from-bigquery
        #   Exporting Data From BigQuery
        #
        # @param [Google::Cloud::Storage::File, String, Array<String>]
        #   extract_url The Google Storage file or file URI pattern(s) to which
        #   BigQuery should extract the table data.
        # @param [String] format The exported file format. The default value is
        #   `csv`.
        #
        #   The following values are supported:
        #
        #   * `csv` - CSV
        #   * `json` - [Newline-delimited JSON](http://jsonlines.org/)
        #   * `avro` - [Avro](http://avro.apache.org/)
        # @param [String] compression The compression type to use for exported
        #   files. Possible values include `GZIP` and `NONE`. The default value
        #   is `NONE`.
        # @param [String] delimiter Delimiter to use between fields in the
        #   exported data. Default is <code>,</code>.
        # @param [Boolean] header Whether to print out a header row in the
        #   results. Default is `true`.
        #
        #
        # @return [Boolean] Returns `true` if the extract operation succeeded.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   table.extract "gs://my-bucket/file-name.json", format: "json"
        #
        # @!group Data
        #
        def extract extract_url, format: nil, compression: nil, delimiter: nil,
                    header: nil
          job = extract_job extract_url, format: format,
                                         compression: compression,
                                         delimiter: delimiter, header: header
          job.wait_until_done!

          if job.failed?
            begin
              # raise to activate ruby exception cause handling
              fail job.gapi_error
            rescue => e
              # wrap Google::Apis::Error with Google::Cloud::Error
              raise Google::Cloud::Error.from_error(e)
            end
          end

          true
        end

        ##
        # Loads data into the table. You can pass a google-cloud storage file
        # path or a google-cloud storage file instance. Or, you can upload a
        # file directly. See [Loading Data with a POST Request](
        # https://cloud.google.com/bigquery/loading-data-post-request#multipart).
        #
        # @param [File, Google::Cloud::Storage::File, String] file A file or the
        #   URI of a Google Cloud Storage file containing data to load into the
        #   table.
        # @param [String] format The exported file format. The default value is
        #   `csv`.
        #
        #   The following values are supported:
        #
        #   * `csv` - CSV
        #   * `json` - [Newline-delimited JSON](http://jsonlines.org/)
        #   * `avro` - [Avro](http://avro.apache.org/)
        #   * `datastore_backup` - Cloud Datastore backup
        # @param [String] create Specifies whether the job is allowed to create
        #   new tables. The default value is `needed`.
        #
        #   The following values are supported:
        #
        #   * `needed` - Create the table if it does not exist.
        #   * `never` - The table must already exist. A 'notFound' error is
        #     raised if the table does not exist.
        # @param [String] write Specifies how to handle data already present in
        #   the table. The default value is `append`.
        #
        #   The following values are supported:
        #
        #   * `truncate` - BigQuery overwrites the table data.
        #   * `append` - BigQuery appends the data to the table.
        #   * `empty` - An error will be returned if the table already contains
        #     data.
        # @param [Array<String>] projection_fields If the `format` option is set
        #   to `datastore_backup`, indicates which entity properties to load
        #   from a Cloud Datastore backup. Property names are case sensitive and
        #   must be top-level properties. If not set, BigQuery loads all
        #   properties. If any named property isn't found in the Cloud Datastore
        #   backup, an invalid error is returned.
        # @param [Boolean] jagged_rows Accept rows that are missing trailing
        #   optional columns. The missing values are treated as nulls. If
        #   `false`, records with missing trailing columns are treated as bad
        #   records, and if there are too many bad records, an invalid error is
        #   returned in the job result. The default value is `false`. Only
        #   applicable to CSV, ignored for other formats.
        # @param [Boolean] quoted_newlines Indicates if BigQuery should allow
        #   quoted data sections that contain newline characters in a CSV file.
        #   The default value is `false`.
        # @param [Boolean] autodetect Indicates if BigQuery should
        #   automatically infer the options and schema for CSV and JSON sources.
        #   The default value is `false`.
        # @param [String] encoding The character encoding of the data. The
        #   supported values are `UTF-8` or `ISO-8859-1`. The default value is
        #   `UTF-8`.
        # @param [String] delimiter Specifices the separator for fields in a CSV
        #   file. BigQuery converts the string to `ISO-8859-1` encoding, and
        #   then uses the first byte of the encoded string to split the data in
        #   its raw, binary state. Default is <code>,</code>.
        # @param [Boolean] ignore_unknown Indicates if BigQuery should allow
        #   extra values that are not represented in the table schema. If true,
        #   the extra values are ignored. If false, records with extra columns
        #   are treated as bad records, and if there are too many bad records,
        #   an invalid error is returned in the job result. The default value is
        #   `false`.
        #
        #   The `format` property determines what BigQuery treats as an extra
        #   value:
        #
        #   * `CSV`: Trailing columns
        #   * `JSON`: Named values that don't match any column names
        # @param [Integer] max_bad_records The maximum number of bad records
        #   that BigQuery can ignore when running the job. If the number of bad
        #   records exceeds this value, an invalid error is returned in the job
        #   result. The default value is `0`, which requires that all records
        #   are valid.
        # @param [String] null_marker Specifies a string that represents a null
        #   value in a CSV file. For example, if you specify `\N`, BigQuery
        #   interprets `\N` as a null value when loading a CSV file. The default
        #   value is the empty string. If you set this property to a custom
        #   value, BigQuery throws an error if an empty string is present for
        #   all data types except for STRING and BYTE. For STRING and BYTE
        #   columns, BigQuery interprets the empty string as an empty value.
        # @param [String] quote The value that is used to quote data sections in
        #   a CSV file. BigQuery converts the string to ISO-8859-1 encoding, and
        #   then uses the first byte of the encoded string to split the data in
        #   its raw, binary state. The default value is a double-quote
        #   <code>"</code>. If your data does not contain quoted sections, set
        #   the property value to an empty string. If your data contains quoted
        #   newline characters, you must also set the allowQuotedNewlines
        #   property to true.
        # @param [Integer] skip_leading The number of rows at the top of a CSV
        #   file that BigQuery will skip when loading the data. The default
        #   value is `0`. This property is useful if you have header rows in the
        #   file that should be skipped.
        # @param [String] job_id A user-defined ID for the load job. The ID
        #   must contain only letters (a-z, A-Z), numbers (0-9), underscores
        #   (_), or dashes (-). The maximum length is 1,024 characters. If
        #   `job_id` is provided, then `prefix` will not be used.
        #
        #   See [Generating a job
        #   ID](https://cloud.google.com/bigquery/docs/managing-jobs#generate-jobid).
        # @param [String] prefix A string, usually human-readable, that will be
        #   prepended to a generated value to produce a unique job ID. For
        #   example, the prefix `daily_import_job_` can be given to generate a
        #   job ID such as `daily_import_job_12vEDtMQ0mbp1Mo5Z7mzAFQJZazh`. The
        #   prefix must contain only letters (a-z, A-Z), numbers (0-9),
        #   underscores (_), or dashes (-). The maximum length of the entire ID
        #   is 1,024 characters. If `job_id` is provided, then `prefix` will not
        #   be used.
        # @param [Hash] labels A hash of user-provided labels associated with
        #   the job. You can use these to organize and group your jobs. Label
        #   keys and values can be no longer than 63 characters, can only
        #   contain lowercase letters, numeric characters, underscores and
        #   dashes. International characters are allowed. Label values are
        #   optional. Label keys must start with a letter and each label in the
        #   list must have a different key.
        #
        # @return [Google::Cloud::Bigquery::LoadJob]
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   load_job = table.load_job "gs://my-bucket/file-name.csv"
        #
        # @example Pass a google-cloud-storage `File` instance:
        #   require "google/cloud/bigquery"
        #   require "google/cloud/storage"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "file-name.csv"
        #   load_job = table.load_job file
        #
        # @example Upload a file directly:
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   file = File.open "my_data.csv"
        #   load_job = table.load_job file
        #
        # @!group Data
        #
        def load_job file, format: nil, create: nil, write: nil,
                     projection_fields: nil, jagged_rows: nil,
                     quoted_newlines: nil, encoding: nil, delimiter: nil,
                     ignore_unknown: nil, max_bad_records: nil, quote: nil,
                     skip_leading: nil, dryrun: nil, job_id: nil, prefix: nil,
                     labels: nil, autodetect: nil, null_marker: nil
          ensure_service!
          options = { format: format, create: create, write: write,
                      projection_fields: projection_fields,
                      jagged_rows: jagged_rows,
                      quoted_newlines: quoted_newlines, encoding: encoding,
                      delimiter: delimiter, ignore_unknown: ignore_unknown,
                      max_bad_records: max_bad_records, quote: quote,
                      skip_leading: skip_leading, dryrun: dryrun,
                      job_id: job_id, prefix: prefix, labels: labels,
                      autodetect: autodetect, null_marker: null_marker }
          return load_storage(file, options) if storage_url? file
          return load_local(file, options) if local_file? file
          fail Google::Cloud::Error, "Don't know how to load #{file}"
        end

        ##
        # Loads data into the table. You can pass a google-cloud storage file
        # path or a google-cloud storage file instance. Or, you can upload a
        # file directly. See [Loading Data with a POST Request](
        # https://cloud.google.com/bigquery/loading-data-post-request#multipart).
        #
        # @param [File, Google::Cloud::Storage::File, String] file A file or the
        #   URI of a Google Cloud Storage file containing data to load into the
        #   table.
        # @param [String] format The exported file format. The default value is
        #   `csv`.
        #
        #   The following values are supported:
        #
        #   * `csv` - CSV
        #   * `json` - [Newline-delimited JSON](http://jsonlines.org/)
        #   * `avro` - [Avro](http://avro.apache.org/)
        #   * `datastore_backup` - Cloud Datastore backup
        # @param [String] create Specifies whether the job is allowed to create
        #   new tables. The default value is `needed`.
        #
        #   The following values are supported:
        #
        #   * `needed` - Create the table if it does not exist.
        #   * `never` - The table must already exist. A 'notFound' error is
        #     raised if the table does not exist.
        # @param [String] write Specifies how to handle data already present in
        #   the table. The default value is `append`.
        #
        #   The following values are supported:
        #
        #   * `truncate` - BigQuery overwrites the table data.
        #   * `append` - BigQuery appends the data to the table.
        #   * `empty` - An error will be returned if the table already contains
        #     data.
        # @param [Array<String>] projection_fields If the `format` option is set
        #   to `datastore_backup`, indicates which entity properties to load
        #   from a Cloud Datastore backup. Property names are case sensitive and
        #   must be top-level properties. If not set, BigQuery loads all
        #   properties. If any named property isn't found in the Cloud Datastore
        #   backup, an invalid error is returned.
        # @param [Boolean] jagged_rows Accept rows that are missing trailing
        #   optional columns. The missing values are treated as nulls. If
        #   `false`, records with missing trailing columns are treated as bad
        #   records, and if there are too many bad records, an invalid error is
        #   returned in the job result. The default value is `false`. Only
        #   applicable to CSV, ignored for other formats.
        # @param [Boolean] quoted_newlines Indicates if BigQuery should allow
        #   quoted data sections that contain newline characters in a CSV file.
        #   The default value is `false`.
        # @param [Boolean] autodetect Indicates if BigQuery should
        #   automatically infer the options and schema for CSV and JSON sources.
        #   The default value is `false`.
        # @param [String] encoding The character encoding of the data. The
        #   supported values are `UTF-8` or `ISO-8859-1`. The default value is
        #   `UTF-8`.
        # @param [String] delimiter Specifices the separator for fields in a CSV
        #   file. BigQuery converts the string to `ISO-8859-1` encoding, and
        #   then uses the first byte of the encoded string to split the data in
        #   its raw, binary state. Default is <code>,</code>.
        # @param [Boolean] ignore_unknown Indicates if BigQuery should allow
        #   extra values that are not represented in the table schema. If true,
        #   the extra values are ignored. If false, records with extra columns
        #   are treated as bad records, and if there are too many bad records,
        #   an invalid error is returned in the job result. The default value is
        #   `false`.
        #
        #   The `format` property determines what BigQuery treats as an extra
        #   value:
        #
        #   * `CSV`: Trailing columns
        #   * `JSON`: Named values that don't match any column names
        # @param [Integer] max_bad_records The maximum number of bad records
        #   that BigQuery can ignore when running the job. If the number of bad
        #   records exceeds this value, an invalid error is returned in the job
        #   result. The default value is `0`, which requires that all records
        #   are valid.
        # @param [String] null_marker Specifies a string that represents a null
        #   value in a CSV file. For example, if you specify `\N`, BigQuery
        #   interprets `\N` as a null value when loading a CSV file. The default
        #   value is the empty string. If you set this property to a custom
        #   value, BigQuery throws an error if an empty string is present for
        #   all data types except for STRING and BYTE. For STRING and BYTE
        #   columns, BigQuery interprets the empty string as an empty value.
        # @param [String] quote The value that is used to quote data sections in
        #   a CSV file. BigQuery converts the string to ISO-8859-1 encoding, and
        #   then uses the first byte of the encoded string to split the data in
        #   its raw, binary state. The default value is a double-quote
        #   <code>"</code>. If your data does not contain quoted sections, set
        #   the property value to an empty string. If your data contains quoted
        #   newline characters, you must also set the allowQuotedNewlines
        #   property to true.
        # @param [Integer] skip_leading The number of rows at the top of a CSV
        #   file that BigQuery will skip when loading the data. The default
        #   value is `0`. This property is useful if you have header rows in the
        #   file that should be skipped.
        #
        # @return [Google::Cloud::Bigquery::LoadJob]
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   load_job = table.load_job "gs://my-bucket/file-name.csv"
        #
        # @example Pass a google-cloud-storage `File` instance:
        #   require "google/cloud/bigquery"
        #   require "google/cloud/storage"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "file-name.csv"
        #   load_job = table.load_job file
        #
        # @example Upload a file directly:
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   file = File.open "my_data.csv"
        #   load_job = table.load_job file
        #
        # @!group Data
        #
        def load file, format: nil, create: nil, write: nil,
                 projection_fields: nil, jagged_rows: nil, quoted_newlines: nil,
                 encoding: nil, delimiter: nil, ignore_unknown: nil,
                 max_bad_records: nil, quote: nil, skip_leading: nil,
                 autodetect: nil, null_marker: nil
          job = load_job file, format: format, create: create, write: write,
                               projection_fields: projection_fields,
                               jagged_rows: jagged_rows,
                               quoted_newlines: quoted_newlines,
                               encoding: encoding, delimiter: delimiter,
                               ignore_unknown: ignore_unknown,
                               max_bad_records: max_bad_records, quote: quote,
                               skip_leading: skip_leading,
                               autodetect: autodetect, null_marker: null_marker

          job.wait_until_done!

          if job.failed?
            begin
              # raise to activate ruby exception cause handling
              fail job.gapi_error
            rescue => e
              # wrap Google::Apis::Error with Google::Cloud::Error
              raise Google::Cloud::Error.from_error(e)
            end
          end

          true
        end

        ##
        # Inserts data into the table for near-immediate querying, without the
        # need to complete a load operation before the data can appear in query
        # results.
        #
        # @see https://cloud.google.com/bigquery/streaming-data-into-bigquery
        #   Streaming Data Into BigQuery
        #
        # @param [Hash, Array<Hash>] rows A hash object or array of hash objects
        #   containing the data. Required.
        # @param [Boolean] skip_invalid Insert all valid rows of a request, even
        #   if invalid rows exist. The default value is `false`, which causes
        #   the entire request to fail if any invalid rows exist.
        # @param [Boolean] ignore_unknown Accept rows that contain values that
        #   do not match the schema. The unknown values are ignored. Default is
        #   false, which treats unknown values as errors.
        #
        # @return [Google::Cloud::Bigquery::InsertResponse]
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   rows = [
        #     { "first_name" => "Alice", "age" => 21 },
        #     { "first_name" => "Bob", "age" => 22 }
        #   ]
        #   table.insert rows
        #
        # @!group Data
        #
        def insert rows, skip_invalid: nil, ignore_unknown: nil
          rows = [rows] if rows.is_a? Hash
          fail ArgumentError, "No rows provided" if rows.empty?
          rows = Convert.to_json_rows rows
          ensure_service!
          options = { skip_invalid: skip_invalid,
                      ignore_unknown: ignore_unknown }
          gapi = service.insert_tabledata dataset_id, table_id, rows, options
          InsertResponse.from_gapi rows, gapi
        end

        ##
        # Create an asynchonous inserter object used to insert rows in batches.
        #
        # @param [Boolean] skip_invalid Insert all valid rows of a request, even
        #   if invalid rows exist. The default value is `false`, which causes
        #   the entire request to fail if any invalid rows exist.
        # @param [Boolean] ignore_unknown Accept rows that contain values that
        #   do not match the schema. The unknown values are ignored. Default is
        #   false, which treats unknown values as errors.
        # @attr_reader [Integer] max_bytes The maximum size of rows to be
        #   collected before the batch is published. Default is 10,000,000
        #   (10MB).
        # @param [Integer] max_rows The maximum number of rows to be collected
        #   before the batch is published. Default is 500.
        # @attr_reader [Numeric] interval The number of seconds to collect
        #   messages before the batch is published. Default is 10.
        # @attr_reader [Numeric] threads The number of threads used to insert
        #   batches of rows. Default is 4.
        # @yield [response] the callback for when a batch of rows is inserted
        # @yieldparam [InsertResponse] response the result of the asynchonous
        #   insert
        #
        # @return [Table::AsyncInserter] Returns inserter object.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #   inserter = table.insert_async do |response|
        #     log_insert "inserted #{response.insert_count} rows " \
        #       "with #{response.error_count} errors"
        #   end
        #
        #   rows = [
        #     { "first_name" => "Alice", "age" => 21 },
        #     { "first_name" => "Bob", "age" => 22 }
        #   ]
        #   inserter.insert rows
        #
        #   inserter.stop.wait!
        #
        def insert_async skip_invalid: nil, ignore_unknown: nil,
                         max_bytes: 10000000, max_rows: 500, interval: 10,
                         threads: 4, &block
          ensure_service!

          AsyncInserter.new self, skip_invalid: skip_invalid,
                                  ignore_unknown: ignore_unknown,
                                  max_bytes: max_bytes, max_rows: max_rows,
                                  interval: interval, threads: threads, &block
        end

        ##
        # Permanently deletes the table.
        #
        # @return [Boolean] Returns `true` if the table was deleted.
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.table "my_table"
        #
        #   table.delete
        #
        # @!group Lifecycle
        #
        def delete
          ensure_service!
          service.delete_table dataset_id, table_id
          true
        end

        ##
        # Reloads the table with current data from the BigQuery service.
        #
        # @!group Lifecycle
        #
        def reload!
          ensure_service!
          gapi = service.get_table dataset_id, table_id
          @gapi = gapi
        end
        alias_method :refresh!, :reload!

        ##
        # @private New Table from a Google API Client object.
        def self.from_gapi gapi, conn
          klass = class_for gapi
          klass.new.tap do |f|
            f.gapi = gapi
            f.service = conn
          end
        end

        protected

        ##
        # Raise an error unless an active service is available.
        def ensure_service!
          fail "Must have active connection" unless service
        end

        def patch_gapi! *attributes
          return if attributes.empty?
          ensure_service!
          patch_args = Hash[attributes.map do |attr|
            [attr, @gapi.send(attr)]
          end]
          patch_gapi = Google::Apis::BigqueryV2::Table.new patch_args
          patch_gapi.etag = etag if etag
          @gapi = service.patch_table dataset_id, table_id, patch_gapi

          # TODO: restore original impl after acceptance test indicates that
          # service etag bug is fixed
          reload!
        end

        def self.class_for gapi
          return View if gapi.type == "VIEW"
          self
        end

        def load_storage url, options = {}
          # Convert to storage URL
          url = url.to_gs_url if url.respond_to? :to_gs_url

          gapi = service.load_table_gs_url dataset_id, table_id, url, options
          Job.from_gapi gapi, service
        end

        def load_local file, options = {}
          # Convert to storage URL
          file = file.to_gs_url if file.respond_to? :to_gs_url

          gapi = service.load_table_file dataset_id, table_id, file, options
          Job.from_gapi gapi, service
        end

        def storage_url? file
          file.respond_to?(:to_gs_url) ||
            (file.respond_to?(:to_str) &&
            file.to_str.downcase.start_with?("gs://"))
        end

        def local_file? file
          ::File.file? file
        rescue
          false
        end

        ##
        # Load the complete representation of the table if it has been
        # only partially loaded by a request to the API list method.
        def ensure_full_data!
          reload_gapi! unless data_complete?
        end

        def reload_gapi!
          ensure_service!
          gapi = service.get_table dataset_id, table_id
          @gapi = gapi
        end

        def data_complete?
          @gapi.is_a? Google::Apis::BigqueryV2::Table
        end

        private

        def get_table_ref table
          if table.respond_to? :table_ref
            table.table_ref
          else
            Service.table_ref_from_s table, table_ref
          end
        end

        ##
        # Yielded to a block to accumulate changes for a patch request.
        class Updater < Table
          ##
          # A list of attributes that were updated.
          attr_reader :updates

          ##
          # Create an Updater object.
          def initialize gapi
            @updates = []
            @gapi = gapi
            @schema = nil
          end

          ##
          # Returns the table's schema. This method can also be used to set,
          # replace, or add to the schema by passing a block. See {Schema} for
          # available methods.
          #
          # @param [Boolean] replace Whether to replace the existing schema with
          #   the new schema. If `true`, the fields will replace the existing
          #   schema. If `false`, the fields will be added to the existing
          #   schema. When a table already contains data, schema changes must be
          #   additive. Thus, the default value is `false`.
          # @yield [schema] a block for setting the schema
          # @yieldparam [Schema] schema the object accepting the schema
          #
          # @return [Google::Cloud::Bigquery::Schema]
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |t|
          #     t.name = "My Table",
          #     t.description = "A description of my table."
          #     t.schema do |s|
          #       s.string "first_name", mode: :required
          #       s.record "cities_lived", mode: :repeated do |r|
          #         r.string "place", mode: :required
          #         r.integer "number_of_years", mode: :required
          #       end
          #     end
          #   end
          #
          # @!group Schema
          #
          def schema replace: false
            # Same as Table#schema, but not frozen
            # TODO: make sure to call ensure_full_data! on Dataset#update
            @schema ||= Schema.from_gapi @gapi.schema
            if block_given?
              @schema = Schema.from_gapi if replace
              yield @schema
              check_for_mutated_schema!
            end
            # Do not freeze on updater, allow modifications
            @schema
          end

          ##
          # Adds a string field to the schema.
          #
          # See {Schema#string}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.string "first_name", mode: :required
          #   end
          #
          # @!group Schema
          def string name, description: nil, mode: :nullable
            schema.string name, description: description, mode: mode
          end

          ##
          # Adds an integer field to the schema.
          #
          # See {Schema#integer}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.integer "age", mode: :required
          #   end
          #
          # @!group Schema
          def integer name, description: nil, mode: :nullable
            schema.integer name, description: description, mode: mode
          end

          ##
          # Adds a floating-point number field to the schema.
          #
          # See {Schema#float}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.float "price", mode: :required
          #   end
          #
          # @!group Schema
          def float name, description: nil, mode: :nullable
            schema.float name, description: description, mode: mode
          end

          ##
          # Adds a boolean field to the schema.
          #
          # See {Schema#boolean}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.boolean "active", mode: :required
          #   end
          #
          # @!group Schema
          def boolean name, description: nil, mode: :nullable
            schema.boolean name, description: description, mode: mode
          end

          ##
          # Adds a bytes field to the schema.
          #
          # See {Schema#bytes}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.bytes "avatar", mode: :required
          #   end
          #
          # @!group Schema
          def bytes name, description: nil, mode: :nullable
            schema.bytes name, description: description, mode: mode
          end

          ##
          # Adds a timestamp field to the schema.
          #
          # See {Schema#timestamp}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.timestamp "creation_date", mode: :required
          #   end
          #
          # @!group Schema
          def timestamp name, description: nil, mode: :nullable
            schema.timestamp name, description: description, mode: mode
          end

          ##
          # Adds a time field to the schema.
          #
          # See {Schema#time}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.time "duration", mode: :required
          #   end
          #
          # @!group Schema
          def time name, description: nil, mode: :nullable
            schema.time name, description: description, mode: mode
          end

          ##
          # Adds a datetime field to the schema.
          #
          # See {Schema#datetime}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.datetime "target_end", mode: :required
          #   end
          #
          # @!group Schema
          def datetime name, description: nil, mode: :nullable
            schema.datetime name, description: description, mode: mode
          end

          ##
          # Adds a date field to the schema.
          #
          # See {Schema#date}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.date "birthday", mode: :required
          #   end
          #
          # @!group Schema
          def date name, description: nil, mode: :nullable
            schema.date name, description: description, mode: mode
          end

          ##
          # Adds a record field to the schema. A block must be passed describing
          # the nested fields of the record. For more information about nested
          # and repeated records, see [Preparing Data for BigQuery
          # ](https://cloud.google.com/bigquery/preparing-data-for-bigquery).
          #
          # See {Schema#record}.
          #
          # @param [String] name The field name. The name must contain only
          #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
          #   start with a letter or underscore. The maximum length is 128
          #   characters.
          # @param [String] description A description of the field.
          # @param [Symbol] mode The field's mode. The possible values are
          #   `:nullable`, `:required`, and `:repeated`. The default value is
          #   `:nullable`.
          # @yield [nested_schema] a block for setting the nested schema
          # @yieldparam [Schema] nested_schema the object accepting the
          #   nested schema
          #
          # @example
          #   require "google/cloud/bigquery"
          #
          #   bigquery = Google::Cloud::Bigquery.new
          #   dataset = bigquery.dataset "my_dataset"
          #   table = dataset.create_table "my_table" do |schema|
          #     schema.record "cities_lived", mode: :repeated do |cities_lived|
          #       cities_lived.string "place", mode: :required
          #       cities_lived.integer "number_of_years", mode: :required
          #     end
          #   end
          #
          # @!group Schema
          #
          def record name, description: nil, mode: nil, &block
            schema.record name, description: description, mode: mode, &block
          end

          ##
          # Make sure any access changes are saved
          def check_for_mutated_schema!
            return if @schema.nil?
            return unless @schema.changed?
            @gapi.schema = @schema.to_gapi
            patch_gapi! :schema
          end

          def to_gapi
            check_for_mutated_schema!
            @gapi
          end

          protected

          ##
          # Change to a NOOP
          def ensure_full_data!
            # Do nothing because we trust the gapi is full before we get here.
          end

          ##
          # Queue up all the updates instead of making them.
          def patch_gapi! attribute
            @updates << attribute
            @updates.uniq!
          end
        end
      end
    end
  end
end
