/*
 * Copyright 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "gcda_parser.h"
#include "gcda_basic_io.h"

#include <iostream>
#include <vector>

/*
 * To test locally:
 * $ rm a.out; gcc gcda_parser.cpp gcov_basic_io.cpp -lstdc++; ./a.out
 */

using namespace std;

int main() {
  std::vector<unsigned>* result =
      android::vts::parse_gcda_file("testdata/lights.gcda");
  if (result) {
    for (unsigned int index = 0; index < result->size(); index++) {
      cout << result->at(index) << endl;
    }
    delete result;
  }
  return 0;
}
