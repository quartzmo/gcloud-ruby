# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: google/cloud/dataproc/v1/jobs.proto


require 'google/protobuf'

require 'google/api/annotations_pb'
require 'google/api/client_pb'
require 'google/api/field_behavior_pb'
require 'google/protobuf/empty_pb'
require 'google/protobuf/field_mask_pb'
require 'google/protobuf/timestamp_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "google.cloud.dataproc.v1.LoggingConfig" do
    map :driver_log_levels, :string, :enum, 2, "google.cloud.dataproc.v1.LoggingConfig.Level"
  end
  add_enum "google.cloud.dataproc.v1.LoggingConfig.Level" do
    value :LEVEL_UNSPECIFIED, 0
    value :ALL, 1
    value :TRACE, 2
    value :DEBUG, 3
    value :INFO, 4
    value :WARN, 5
    value :ERROR, 6
    value :FATAL, 7
    value :OFF, 8
  end
  add_message "google.cloud.dataproc.v1.HadoopJob" do
    repeated :args, :string, 3
    repeated :jar_file_uris, :string, 4
    repeated :file_uris, :string, 5
    repeated :archive_uris, :string, 6
    map :properties, :string, :string, 7
    optional :logging_config, :message, 8, "google.cloud.dataproc.v1.LoggingConfig"
    oneof :driver do
      optional :main_jar_file_uri, :string, 1
      optional :main_class, :string, 2
    end
  end
  add_message "google.cloud.dataproc.v1.SparkJob" do
    repeated :args, :string, 3
    repeated :jar_file_uris, :string, 4
    repeated :file_uris, :string, 5
    repeated :archive_uris, :string, 6
    map :properties, :string, :string, 7
    optional :logging_config, :message, 8, "google.cloud.dataproc.v1.LoggingConfig"
    oneof :driver do
      optional :main_jar_file_uri, :string, 1
      optional :main_class, :string, 2
    end
  end
  add_message "google.cloud.dataproc.v1.PySparkJob" do
    optional :main_python_file_uri, :string, 1
    repeated :args, :string, 2
    repeated :python_file_uris, :string, 3
    repeated :jar_file_uris, :string, 4
    repeated :file_uris, :string, 5
    repeated :archive_uris, :string, 6
    map :properties, :string, :string, 7
    optional :logging_config, :message, 8, "google.cloud.dataproc.v1.LoggingConfig"
  end
  add_message "google.cloud.dataproc.v1.QueryList" do
    repeated :queries, :string, 1
  end
  add_message "google.cloud.dataproc.v1.HiveJob" do
    optional :continue_on_failure, :bool, 3
    map :script_variables, :string, :string, 4
    map :properties, :string, :string, 5
    repeated :jar_file_uris, :string, 6
    oneof :queries do
      optional :query_file_uri, :string, 1
      optional :query_list, :message, 2, "google.cloud.dataproc.v1.QueryList"
    end
  end
  add_message "google.cloud.dataproc.v1.SparkSqlJob" do
    map :script_variables, :string, :string, 3
    map :properties, :string, :string, 4
    repeated :jar_file_uris, :string, 56
    optional :logging_config, :message, 6, "google.cloud.dataproc.v1.LoggingConfig"
    oneof :queries do
      optional :query_file_uri, :string, 1
      optional :query_list, :message, 2, "google.cloud.dataproc.v1.QueryList"
    end
  end
  add_message "google.cloud.dataproc.v1.PigJob" do
    optional :continue_on_failure, :bool, 3
    map :script_variables, :string, :string, 4
    map :properties, :string, :string, 5
    repeated :jar_file_uris, :string, 6
    optional :logging_config, :message, 7, "google.cloud.dataproc.v1.LoggingConfig"
    oneof :queries do
      optional :query_file_uri, :string, 1
      optional :query_list, :message, 2, "google.cloud.dataproc.v1.QueryList"
    end
  end
  add_message "google.cloud.dataproc.v1.JobPlacement" do
    optional :cluster_name, :string, 1
    optional :cluster_uuid, :string, 2
  end
  add_message "google.cloud.dataproc.v1.JobStatus" do
    optional :state, :enum, 1, "google.cloud.dataproc.v1.JobStatus.State"
    optional :details, :string, 2
    optional :state_start_time, :message, 6, "google.protobuf.Timestamp"
    optional :substate, :enum, 7, "google.cloud.dataproc.v1.JobStatus.Substate"
  end
  add_enum "google.cloud.dataproc.v1.JobStatus.State" do
    value :STATE_UNSPECIFIED, 0
    value :PENDING, 1
    value :SETUP_DONE, 8
    value :RUNNING, 2
    value :CANCEL_PENDING, 3
    value :CANCEL_STARTED, 7
    value :CANCELLED, 4
    value :DONE, 5
    value :ERROR, 6
    value :ATTEMPT_FAILURE, 9
  end
  add_enum "google.cloud.dataproc.v1.JobStatus.Substate" do
    value :UNSPECIFIED, 0
    value :SUBMITTED, 1
    value :QUEUED, 2
    value :STALE_STATUS, 3
  end
  add_message "google.cloud.dataproc.v1.JobReference" do
    optional :project_id, :string, 1
    optional :job_id, :string, 2
  end
  add_message "google.cloud.dataproc.v1.YarnApplication" do
    optional :name, :string, 1
    optional :state, :enum, 2, "google.cloud.dataproc.v1.YarnApplication.State"
    optional :progress, :float, 3
    optional :tracking_url, :string, 4
  end
  add_enum "google.cloud.dataproc.v1.YarnApplication.State" do
    value :STATE_UNSPECIFIED, 0
    value :NEW, 1
    value :NEW_SAVING, 2
    value :SUBMITTED, 3
    value :ACCEPTED, 4
    value :RUNNING, 5
    value :FINISHED, 6
    value :FAILED, 7
    value :KILLED, 8
  end
  add_message "google.cloud.dataproc.v1.Job" do
    optional :reference, :message, 1, "google.cloud.dataproc.v1.JobReference"
    optional :placement, :message, 2, "google.cloud.dataproc.v1.JobPlacement"
    optional :status, :message, 8, "google.cloud.dataproc.v1.JobStatus"
    repeated :status_history, :message, 13, "google.cloud.dataproc.v1.JobStatus"
    repeated :yarn_applications, :message, 9, "google.cloud.dataproc.v1.YarnApplication"
    optional :driver_output_resource_uri, :string, 17
    optional :driver_control_files_uri, :string, 15
    map :labels, :string, :string, 18
    optional :scheduling, :message, 20, "google.cloud.dataproc.v1.JobScheduling"
    optional :job_uuid, :string, 22
    oneof :type_job do
      optional :hadoop_job, :message, 3, "google.cloud.dataproc.v1.HadoopJob"
      optional :spark_job, :message, 4, "google.cloud.dataproc.v1.SparkJob"
      optional :pyspark_job, :message, 5, "google.cloud.dataproc.v1.PySparkJob"
      optional :hive_job, :message, 6, "google.cloud.dataproc.v1.HiveJob"
      optional :pig_job, :message, 7, "google.cloud.dataproc.v1.PigJob"
      optional :spark_sql_job, :message, 12, "google.cloud.dataproc.v1.SparkSqlJob"
    end
  end
  add_message "google.cloud.dataproc.v1.JobScheduling" do
    optional :max_failures_per_hour, :int32, 1
  end
  add_message "google.cloud.dataproc.v1.SubmitJobRequest" do
    optional :project_id, :string, 1
    optional :region, :string, 3
    optional :job, :message, 2, "google.cloud.dataproc.v1.Job"
    optional :request_id, :string, 4
  end
  add_message "google.cloud.dataproc.v1.GetJobRequest" do
    optional :project_id, :string, 1
    optional :region, :string, 3
    optional :job_id, :string, 2
  end
  add_message "google.cloud.dataproc.v1.ListJobsRequest" do
    optional :project_id, :string, 1
    optional :region, :string, 6
    optional :page_size, :int32, 2
    optional :page_token, :string, 3
    optional :cluster_name, :string, 4
    optional :job_state_matcher, :enum, 5, "google.cloud.dataproc.v1.ListJobsRequest.JobStateMatcher"
    optional :filter, :string, 7
  end
  add_enum "google.cloud.dataproc.v1.ListJobsRequest.JobStateMatcher" do
    value :ALL, 0
    value :ACTIVE, 1
    value :NON_ACTIVE, 2
  end
  add_message "google.cloud.dataproc.v1.UpdateJobRequest" do
    optional :project_id, :string, 1
    optional :region, :string, 2
    optional :job_id, :string, 3
    optional :job, :message, 4, "google.cloud.dataproc.v1.Job"
    optional :update_mask, :message, 5, "google.protobuf.FieldMask"
  end
  add_message "google.cloud.dataproc.v1.ListJobsResponse" do
    repeated :jobs, :message, 1, "google.cloud.dataproc.v1.Job"
    optional :next_page_token, :string, 2
  end
  add_message "google.cloud.dataproc.v1.CancelJobRequest" do
    optional :project_id, :string, 1
    optional :region, :string, 3
    optional :job_id, :string, 2
  end
  add_message "google.cloud.dataproc.v1.DeleteJobRequest" do
    optional :project_id, :string, 1
    optional :region, :string, 3
    optional :job_id, :string, 2
  end
end

module Google
  module Cloud
    module Dataproc
      module V1
        LoggingConfig = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.LoggingConfig").msgclass
        LoggingConfig::Level = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.LoggingConfig.Level").enummodule
        HadoopJob = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.HadoopJob").msgclass
        SparkJob = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.SparkJob").msgclass
        PySparkJob = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.PySparkJob").msgclass
        QueryList = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.QueryList").msgclass
        HiveJob = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.HiveJob").msgclass
        SparkSqlJob = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.SparkSqlJob").msgclass
        PigJob = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.PigJob").msgclass
        JobPlacement = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.JobPlacement").msgclass
        JobStatus = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.JobStatus").msgclass
        JobStatus::State = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.JobStatus.State").enummodule
        JobStatus::Substate = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.JobStatus.Substate").enummodule
        JobReference = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.JobReference").msgclass
        YarnApplication = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.YarnApplication").msgclass
        YarnApplication::State = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.YarnApplication.State").enummodule
        Job = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.Job").msgclass
        JobScheduling = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.JobScheduling").msgclass
        SubmitJobRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.SubmitJobRequest").msgclass
        GetJobRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.GetJobRequest").msgclass
        ListJobsRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.ListJobsRequest").msgclass
        ListJobsRequest::JobStateMatcher = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.ListJobsRequest.JobStateMatcher").enummodule
        UpdateJobRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.UpdateJobRequest").msgclass
        ListJobsResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.ListJobsResponse").msgclass
        CancelJobRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.CancelJobRequest").msgclass
        DeleteJobRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.dataproc.v1.DeleteJobRequest").msgclass
      end
    end
  end
end
