# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: google/cloud/automl/v1beta1/annotation_spec.proto


require 'google/protobuf'

require 'google/api/annotations_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "google.cloud.automl.v1beta1.AnnotationSpec" do
    optional :name, :string, 1
    optional :display_name, :string, 2
    optional :example_count, :int32, 9
  end
end

module Google::Cloud::AutoML::V1beta1
  AnnotationSpec = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.cloud.automl.v1beta1.AnnotationSpec").msgclass
end
