/*
 * Copyright (c) 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License. You may
 * obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package com.android.vts.util;

import com.android.vts.proto.VtsReportMessage.ProfilingReportMessage;
import com.google.common.primitives.Doubles;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import java.util.ArrayList;
import java.util.List;
import org.apache.commons.math3.stat.descriptive.rank.Percentile;

/**
 * Helper object for describing graph data.
 */
public class Histogram extends Graph {

    public static final String PERCENTILES_KEY = "percentiles";
    public static final String PERCENTILE_VALUES_KEY = "percentile_values";

    private List<Double> values;
    private List<String> ids;
    private String xLabel;
    private String yLabel;
    private String name;
    private GraphType type = GraphType.HISTOGRAM;

    public Histogram(String name) {
        this.name = name;
        this.values = new ArrayList<>();
        this.ids = new ArrayList<>();
    }

    /**
     * Get the x axis label.
     * @return The x axis label.
     */
    @Override
    public String getXLabel() {
        return xLabel;
    }

    /**
     * Get the graph type.
     * @return The graph type.
     */
    @Override
    public GraphType getType() {
        return type;
    }

    /**
     * Get the name of the graph.
     * @return The name of the graph.
     */
    @Override
    public String getName() {
        return name;
    }

    /**
     * Get the y axis label.
     * @return The y axis label.
     */
    @Override
    public String getYLabel() {
        return yLabel;
    }

    /**
     * Add data to the graph.
     * @param id The name of the graph.
     * @param profilingReport The profiling report message containing data to add.
     */
    @Override
    public void addData(String id, ProfilingReportMessage profilingReport) {
        if (profilingReport.getValueList().size() == 0 &&
            profilingReport.getStartTimestamp() >= profilingReport.getEndTimestamp()) return;
        xLabel = profilingReport.getXAxisLabel().toStringUtf8();
        yLabel = profilingReport.getYAxisLabel().toStringUtf8();
        for (long value : profilingReport.getValueList()) {
            values.add((double) value);
            ids.add(id);
        }
        if (profilingReport.getStartTimestamp() != profilingReport.getEndTimestamp() &&
            profilingReport.getStartTimestamp() < profilingReport.getEndTimestamp()) {
            values.add((double) profilingReport.getEndTimestamp() -
                       profilingReport.getStartTimestamp());
            ids.add(id);
        }
    }

    /**
     * Serializes the graph to json format.
     * @return A JsonElement object representing the graph object.
     */
    @Override
    public JsonObject toJson() {
        int[] percentiles = {1, 5, 10, 20, 25, 50, 75, 80, 90, 95, 99};
        double[] percentileValues = new double[percentiles.length];
        double[] valueList = Doubles.toArray(values);
        for (int i = 0; i < percentiles.length; i++) {
            percentileValues[i] =
                Math.round(new Percentile().evaluate(valueList, percentiles[i]) * 1000d) / 1000d;
        }
        JsonObject json = super.toJson();
        json.add(VALUE_KEY, new Gson().toJsonTree(values).getAsJsonArray());
        json.add(PERCENTILES_KEY, new Gson().toJsonTree(percentiles).getAsJsonArray());
        json.add(PERCENTILE_VALUES_KEY, new Gson().toJsonTree(percentileValues).getAsJsonArray());
        json.add(IDS_KEY, new Gson().toJsonTree(ids).getAsJsonArray());
        return json;
    }
}
