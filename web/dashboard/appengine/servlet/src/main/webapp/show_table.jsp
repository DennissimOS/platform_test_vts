<%--
  ~ Copyright (c) 2016 Google Inc. All Rights Reserved.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License"); you
  ~ may not use this file except in compliance with the License. You may
  ~ obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
  ~ implied. See the License for the specific language governing
  ~ permissions and limitations under the License.
  --%>
<%@ page contentType='text/html;charset=UTF-8' language='java' %>
<%@ taglib prefix='fn' uri='http://java.sun.com/jsp/jstl/functions' %>
<%@ taglib prefix='c' uri='http://java.sun.com/jsp/jstl/core'%>

<html>
  <head>
    <title>VTS Table</title>
    <link rel='icon' href='//www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_32dp.png' sizes='32x32'>
    <link rel='stylesheet' href='https://fonts.googleapis.com/icon?family=Material+Icons'>
    <link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Roboto:100,300,400,500,700'>
    <link rel='stylesheet' href='https://www.gstatic.com/external_hosted/materialize/all_styles-bundle.css'>
    <link type='text/css' href='/css/navbar.css' rel='stylesheet'>
    <link type='text/css' href='/css/show_table.css' rel='stylesheet'>
    <script src='/js/analytics.js' type='text/javascript'></script>
    <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/3.1.0/jquery.min.js'></script>
    <script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script>
    <script src='https://www.gstatic.com/external_hosted/materialize/materialize.min.js'></script>
    <script src='https://www.gstatic.com/external_hosted/moment/min/moment-with-locales.min.js'></script>
    <script type='text/javascript'>
      if (${analytics_id}) analytics_init(${analytics_id});
      google.charts.load('current', {'packages':['table', 'corechart']});
      google.charts.setOnLoadCallback(drawGridTable);
      google.charts.setOnLoadCallback(drawProfilingTable);
      google.charts.setOnLoadCallback(drawPieChart);
      google.charts.setOnLoadCallback(function() {
          $('.gradient').removeClass('gradient');
      });

      $(document).ready(function() {
          function verify() {
              var oneChecked = ($('#presubmit').prop('checked') ||
                                $('#postsubmit').prop('checked'));
              if (!oneChecked) {
                  $('#refresh').addClass('disabled');
              } else {
                  $('#refresh').removeClass('disabled');
              }
          }
          $('#presubmit').prop('checked', ${showPresubmit} || false)
                         .change(verify);
          $('#postsubmit').prop('checked', ${showPostsubmit} || false)
                          .change(verify);
          $('#refresh').click(refresh);
          $('#help-icon').click(function() {
              $('#help-modal').openModal()
          });
          $('#input-box').keypress(function(e) {
              if (e.which == 13) {
                  refresh();
              }
          });

          // disable buttons on load
          if (!${hasNewer}) {
              $('#newer_button').toggleClass('disabled');
          }
          if (!${hasOlder}) {
              $('#older_button').toggleClass('disabled');
          }
          $('#newer_button').click(prev);
          $('#older_button').click(next);
      });

      // refresh the page to see the selected test types (pre-/post-submit)
      function refresh() {
          if($(this).hasClass('disabled')) return;
          var link = '${pageContext.request.contextPath}' +
              '/show_table?testName=${testName}&startTime=${startTime}' +
              '&endTime=${endTime}';
          var presubmit = $('#presubmit').prop('checked');
          var postsubmit = $('#postsubmit').prop('checked');
          if (presubmit) {
              link += '&showPresubmit=';
          }
          if (postsubmit) {
              link += '&showPostsubmit=';
          }
          if (${unfiltered} && postsubmit && presubmit) {
              link += '&unfiltered=';
          }
          var searchString = $('#input-box').val();
          if (searchString) {
              link += '&search=' + encodeURIComponent(searchString);
          }
          window.open(link,'_self');
      }

      // view older data
      function next() {
          if($(this).hasClass('disabled')) return;
          var endTime = ${startTime};
          var link = '${pageContext.request.contextPath}' +
              '/show_table?testName=${testName}&endTime=' + endTime;
          if ($('#presubmit').prop('checked')) {
              link += '&showPresubmit=';
          }
          if ($('#postsubmit').prop('checked')) {
              link += '&showPostsubmit=';
          }
          if (${unfiltered}) {
              link += '&unfiltered=';
          }
          window.open(link,'_self');
      }

      // view newer data
      function prev() {
          if($(this).hasClass('disabled')) return;
          var startTime = ${endTime};
          var link = '${pageContext.request.contextPath}' +
              '/show_table?testName=${testName}&startTime=' + startTime;
          if ($('#presubmit').prop('checked')) {
              link += '&showPresubmit=';
          }
          if ($('#postsubmit').prop('checked')) {
              link += '&showPostsubmit=';
          }
          if (${unfiltered}) {
              link += '&unfiltered=';
          }
          window.open(link,'_self');
        }

      // table for profiling data
      function drawProfilingTable() {
          errorMessage = ${errorJson} || '';
          if (errorMessage.length > 0) {
              return;
          }
          var data = new google.visualization.DataTable();

          // add columns
          data.addColumn('string', 'Profiling Point Names');

          // add rows
          var profilingPointNameArray = ${profilingPointNameJson};
          var rowArray = new Array(profilingPointNameArray.length);

          for (var i = 0; i < rowArray.length; i++) {
              var row = new Array(1);
              row[0] = profilingPointNameArray[i];
              rowArray[i] = row;
          }
          data.addRows(rowArray);

          var table = new google.visualization.Table(
              document.getElementById('profiling_table_div'));

          var options = {
              showRowNumber: false,
              alternatingRowStyle : true,
              width: '100%',
              sortColumn: 0,
              sortAscending: true,
              cssClassNames: {
                  headerRow : 'table-header'
              }
          };
          table.draw(data, options);

          google.visualization.events.addListener(table, 'select', selectHandler);

          function selectHandler(e) {
              var ctx = '${pageContext.request.contextPath}';
              var link = ctx + '/show_graph?profilingPoint=' +
                  data.getValue(table.getSelection()[0].row, 0) +
                  '&testName=${testName}' +
                  '&startTime=' + ${startTime} +
                  '&endTime=' + ${endTime};
              window.open(link,'_self');
          }
      }

      // to draw pie chart
      function drawPieChart() {
          var topBuildResultCounts = ${topBuildResultCounts};
          if (topBuildResultCounts.length < 1) {
              return;
          }
          var resultNames = ${resultNamesJson};
          var rows = resultNames.map(function(res, i) {
              nickname = res.replace('TEST_CASE_RESULT_', '').replace('_', ' ')
                         .trim().toLowerCase();
              return [nickname, parseInt(topBuildResultCounts[i])];
          });
          rows.unshift(['Result', 'Count']);

          // Get CSS color definitions (or default to white)
          var colors = resultNames.map(function(res) {
              return $('.' + res).css('background-color') || 'white';
          });

          var data = google.visualization.arrayToDataTable(rows);
          var options = {
              is3D: false,
              colors: colors,
              fontName: 'Roboto',
              fontSize: '14px',
              legend: 'none',
              tooltip: {showColorCode: true, ignoreBounds: true},
              chartArea: {height: '90%'}
          };

          var chart = new google.visualization.PieChart(document.getElementById('pie_chart_div'));
          chart.draw(data, options);
      }

      // table for grid data
      function drawGridTable() {
          var data = new google.visualization.DataTable();

          // Add column headers.
          headerRow = ${headerRow};
          headerRow.forEach(function(d, i) {
              var classNames = 'table-header-content';
              if (i == 0) classNames += ' table-header-legend';
              data.addColumn('string', '<span class="' + classNames + '">' +
                             d + '</span>');
          });

          var timeGrid = ${timeGrid};
          var durationGrid = ${durationGrid};
          var summaryGrid = ${summaryGrid};
          var resultsGrid = ${resultsGrid};

          // Format time grid to a formatted date
          timeGrid = timeGrid.map(function(row) {
              return row.map(function(cell, j) {
                  if (j == 0) return cell;
                  var time = moment(cell/1000);
                  // If today, don't display the date
                  if (time.isSame(moment(), 'd')) {
                      return time.format('H:mm:ssZZ');
                  } else {
                      return time.format('M/D/YY H:mm:ssZZ');
                  }
              });
          });

          // Format duration grid to HH:mm:ss.SSS
          durationGrid = durationGrid.map(function(row) {
              return row.map(function(cell, j) {
                  if (j == 0) return cell;
                  return moment.utc(cell/1000).format("HH:mm:ss.SSS");
              });
          });

          // add rows to the data.
          data.addRows(timeGrid);
          data.addRows(durationGrid);
          data.addRows(summaryGrid);
          data.addRows(resultsGrid);

          var table = new google.visualization.Table(document.getElementById('grid_table_div'));
          var classNames = {
              headerRow : 'table-header',
              headerCell : 'table-header-cell'
          };
          var options = {
              showRowNumber: false,
              alternatingRowStyle: true,
              allowHtml: true,
              frozenColumns: 1,
              cssClassNames: classNames,
              sort: 'disable'
          };
          table.draw(data, options);
      }
    </script>

    <nav id='navbar'>
      <div class='nav-wrapper'>
        <span>
          <a href='${pageContext.request.contextPath}/' class='breadcrumb'>VTS Dashboard Home</a>
          <a href='#!' class='breadcrumb'>${testName}</a>
        </span>
        <ul class='right'><li>
          <a id='dropdown-button' class='dropdown-button btn red lighten-3' href='#' data-activates='dropdown'>
            ${email}
          </a>
        </li></ul>
        <ul id='dropdown' class='dropdown-content'>
          <li><a href='${logoutURL}'>Log out</a></li>
        </ul>
      </div>
    </nav>
  </head>

  <body>
    <div class='container'>
      <div class='row'>
        <div class='col s12'>
          <div class='card' id='filter-wrapper'>
            <div id='search-icon-wrapper'>
              <i class='material-icons' id='search-icon'>search</i>
            </div>
            <div class='input-field' id='search-wrapper'>
              <input value='${searchString}' type='text' id='input-box'>
              <label for='input-box'>Search for test results</label>
            </div>
            <div id='help-icon-wrapper'>
              <i class='material-icons' id='help-icon'>help</i>
            </div>
            <div id='build_type_div' class='right'>
              <input type='checkbox' id='presubmit' />
              <label for='presubmit'>Presubmit</label>
              <input type='checkbox' id='postsubmit' />
              <label for='postsubmit'>Postsubmit</label>
              <a id='refresh' class='btn-floating btn-medium red right waves-effect waves-light'>
                <i class='medium material-icons'>cached</i>
              </a>
            </div>
          </div>
        </div>
        <div class='col s6'>
          <div class='col s12 card center-align'>
            <div id='legend_wrapper'>
              <c:forEach items='${resultNames}' var='res'>
                <div class='center-align legend-entry'>
                  <c:set var='trimmed' value='${fn:replace(res, "TEST_CASE_RESULT_", "")}'/>
                  <c:set var='nickname' value='${fn:replace(trimmed, "_", " ")}'/>
                  <label for='${res}'>${nickname}</label>
                  <div id='${res}' class='${res} legend-bubble'></div>
                </div>
              </c:forEach>
            </div>
          </div>
          <div id='profiling_container' class='col s12 card'>
            <c:choose>
              <c:when test='${not empty error}'>
                <div id='error_div' class='center-align'><h5>${error}</h5></div>
              </c:when>
              <c:otherwise>
                <!-- Profiling Table -->
                <div id='profiling_table_div' class='center-align'></div>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
        <div class='col s6 valign-wrapper'>
          <!-- pie chart -->
          <div id='pie-chart-wrapper' class='col s12 valign center-align card'>
            <h6 class='pie-chart-title'>Test Status for Device Build ID: ${topBuildId}</h6>
            <div id='pie_chart_div'></div>
          </div>
        </div>
      </div>

      <div class='col s12'>
        <div id='chart_holder' class='col s12 card'>
          <!-- Grid tables-->
          <div id='grid_table_div'></div>

          <div id='buttons' class='col s12'>
            <a id='newer_button' class='btn-floating waves-effect waves-light red'><i class='material-icons'>keyboard_arrow_left</i></a>
            <a id='older_button' class='btn-floating waves-effect waves-light red right'><i class='material-icons'>keyboard_arrow_right</i></a>
          </div>
        </div>
      </div>
    </div>
    <div id="help-modal" class="modal">
      <div class="modal-content">
        <h4>${searchHelpHeader}</h4>
        <p>${searchHelpBody}</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-action modal-close waves-effect btn-flat">Close</a>
      </div>
    </div>
    <footer class='page-footer'>
      <div class='footer-copyright'>
          <div class='container'>© 2016 - The Android Open Source Project
          </div>
      </div>
    </footer>
  </body>
</html>
