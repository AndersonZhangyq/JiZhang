// import 'package:charts_flutter/flutter.dart' as charts;

import 'package:flutter/material.dart';
import 'package:ji_zhang/widget/chart/compareChart.dart';
import 'package:ji_zhang/widget/chart/trendChart.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({Key? key}) : super(key: key);

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  TabBar get _tabBar => const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.trending_up, color: Colors.black)),
          Tab(icon: Icon(Icons.compare, color: Colors.black)),
        ],
      );
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: PreferredSize(
              preferredSize: _tabBar.preferredSize,
              child: Material(
                color: Colors.white,
                child: Theme(
                    //<-- SEE HERE
                    data: ThemeData(),
                    child: _tabBar),
              ),
            ),
            backgroundColor: Colors.white,
            toolbarHeight: 0,
          ),
          body: const TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              TrendChartWidget(),
              CompareChartWidget(),
            ],
          ),
        ),
      ),
    ));
  }
}
