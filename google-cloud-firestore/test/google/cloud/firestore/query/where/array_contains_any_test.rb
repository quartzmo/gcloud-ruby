# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Google::Cloud::Firestore::Query, :where, :array_contains_any, :mock_firestore do
  let(:query) { Google::Cloud::Firestore::Query.start nil, "#{firestore.path}/documents", firestore }

  it "using array-contains-any" do
    expected_query = Google::Firestore::V1::StructuredQuery.new(
      where: Google::Firestore::V1::StructuredQuery::Filter.new(
        field_filter: Google::Firestore::V1::StructuredQuery::FieldFilter.new(
          field: Google::Firestore::V1::StructuredQuery::FieldReference.new(field_path: "foo"),
          op: :ARRAY_CONTAINS_ANY,
          value: Google::Firestore::V1::Value.new(integer_value: 42)
        )
      )
    )

    generated_query = query.where(:foo, "array-contains-any", 42).query
    generated_query.must_equal expected_query
  end

  it "using array_contains_any" do
    expected_query = Google::Firestore::V1::StructuredQuery.new(
      where: Google::Firestore::V1::StructuredQuery::Filter.new(
        field_filter: Google::Firestore::V1::StructuredQuery::FieldFilter.new(
          field: Google::Firestore::V1::StructuredQuery::FieldReference.new(field_path: "foo"),
          op: :ARRAY_CONTAINS_ANY,
          value: Google::Firestore::V1::Value.new(integer_value: 42)
        )
      )
    )

    generated_query = query.where(:foo, :array_contains_any, 42).query
    generated_query.must_equal expected_query
  end

  it "with multiple values" do
    expected_query = Google::Firestore::V1::StructuredQuery.new(
      where: Google::Firestore::V1::StructuredQuery::Filter.new(
        composite_filter: Google::Firestore::V1::StructuredQuery::CompositeFilter.new(
          op: :AND,
          filters: [
            Google::Firestore::V1::StructuredQuery::Filter.new(
              field_filter: Google::Firestore::V1::StructuredQuery::FieldFilter.new(
                field: Google::Firestore::V1::StructuredQuery::FieldReference.new(field_path: "foo"),
                op: :ARRAY_CONTAINS_ANY,
                value: Google::Firestore::V1::Value.new(integer_value: 42)
              )
            ),
            Google::Firestore::V1::StructuredQuery::Filter.new(
              field_filter: Google::Firestore::V1::StructuredQuery::FieldFilter.new(
                field: Google::Firestore::V1::StructuredQuery::FieldReference.new(field_path: "foo"),
                op: :ARRAY_CONTAINS_ANY,
                value: Google::Firestore::V1::Value.new(integer_value: 43)
              )
            )
          ]
        )
      )
    )

    generated_query = query.where(:foo, :array_contains_any, 42).where(:foo, :array_contains_any, 43).query
    generated_query.must_equal expected_query
  end
end
