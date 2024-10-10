// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/animation.dart';
//
// class Dashboard extends StatefulWidget {
//   @override
//   _DashboardState createState() => _DashboardState();
// }
//
// class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     );
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 2,
//         leading: IconButton(
//           icon: Icon(Icons.dashboard, color: Colors.black),
//           onPressed: () {
//             // Add your action here
//           },
//         ),
//         title: Text('Dashboard', style: TextStyle(color: Colors.black)),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.settings, color: Colors.black),
//             onPressed: () {
//               // Add your action here
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Container(
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   child: Column(
//                     children: [
//                       SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _buildQuickAction(Icons.lightbulb, 'Lights', Colors.orange),
//                           _buildQuickAction(Icons.thermostat, 'Thermostat', Colors.red),
//                           _buildQuickAction(Icons.lock, 'Security', Colors.green),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             SliverToBoxAdapter(
//               child: SizedBox(height: 20),
//             ),
//             SliverToBoxAdapter(
//               child: CarouselSlider(
//                 options: CarouselOptions(
//                   height: 150,
//                   autoPlay: true,
//                   enlargeCenterPage: true,
//                 ),
//                 items: [1, 2, 3, 4, 5].map((i) {
//                   return Builder(
//                     builder: (BuildContext context) {
//                       return Container(
//                         width: MediaQuery.of(context).size.width,
//                         margin: EdgeInsets.symmetric(horizontal: 5.0),
//                         decoration: BoxDecoration(
//                           color: Color(0xFF3B6943),
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         child: Center(
//                             child:Image.asset('assets/images/logo1.png')
//                         ),
//                       );
//                     },
//                   );
//                 }).toList(),
//               ),
//             ),
//             SliverToBoxAdapter(
//               child: SizedBox(height: 20),
//             ),
//
//
//             SliverToBoxAdapter(
//               child: SizedBox(height: 20),
//             ),
//             SliverPadding(
//               padding: EdgeInsets.symmetric(horizontal: 16.0),
//               sliver: SliverToBoxAdapter(
//                 child: Text(
//                   'Rooms',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             SliverPadding(
//               padding: EdgeInsets.symmetric(horizontal: 16.0),
//               sliver: SliverGrid(
//                 delegate: SliverChildBuilderDelegate(
//                       (BuildContext context, int index) {
//                     List<Map<String, String>> rooms = [
//                       {"icon": Icons.tv.codePoint.toString(), "name": "Living room", "devices": "4 devices"},
//                       {"icon": Icons.bed.codePoint.toString(), "name": "Bedroom", "devices": "2 devices"},
//                       {"icon": Icons.kitchen.codePoint.toString(), "name": "Kitchen", "devices": "3 devices"},
//                       {"icon": Icons.bathtub.codePoint.toString(), "name": "Bathroom", "devices": "2 devices"},
//                       {"icon": Icons.desktop_windows.codePoint.toString(), "name": "Office", "devices": "5 devices"},
//                       {"icon": Icons.grass.codePoint.toString(), "name": "Garden", "devices": "1 device"}
//                     ];
//                     var room = rooms[index];
//                     return _buildAnimatedRoomCard(
//                         IconData(int.parse(room["icon"]!), fontFamily: 'MaterialIcons'),
//                         room["name"]!,
//                         room["devices"]!
//                     );
//                   },
//                   childCount: 6,
//                 ),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   mainAxisSpacing: 16.0,
//                   crossAxisSpacing: 16.0,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAnimatedRoomCard(IconData icon, String roomName, String devices) {
//     return ScaleTransition(
//       scale: CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeOut,
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue[300]!, Colors.blue[100]!],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.5),
//               spreadRadius: 2,
//               blurRadius: 5,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 48, color: Colors.white),
//             SizedBox(height: 8),
//             Text(roomName, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
//             SizedBox(height: 4),
//             Text(devices, style: TextStyle(color: Colors.white70)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickAction(IconData icon, String label, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, size: 32, color: color),
//         ),
//         SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue[900]),
//         ),
//       ],
//     );
//   }
// }

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreennn extends StatefulWidget {
  const HomeScreennn({super.key});

  @override
  State<HomeScreennn> createState() => _HomeScreennnState();
}

class _HomeScreennnState extends State<HomeScreennn> {
  List<dynamic>users=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("REST Api call"),
      ),
      body:Center(
        child: Column(
          children: [
            ListView.builder(itemCount: users.length,itemBuilder:(context,index){
              final user=users[index];
              final email=user["email"];
              return ListTile(
                title: Text(email),
              );

            }),
            ElevatedButton.icon(onPressed: fetchUsers,
                label: Text("pressed")),
          ],
        ),
      ) ,
    );
  }

  void fetchUsers()async {
    print("fetchusers called");
    const url="https://randomuser.me/api/?results=5";
    final uri=Uri.parse(url);
    final response=await http.get(uri);
    final body=response.body;
    final json=jsonDecode(body);
    setState(() {
      users=json["results"];
    });
    print("fetch completed");

  }
}