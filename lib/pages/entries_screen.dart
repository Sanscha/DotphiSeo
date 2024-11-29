import 'package:dotphi_seo_app/pages/followup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {

  Widget ToggleButtonWithNavigation(BuildContext context) {
    bool isToggled = false;

    // Function to handle the toggle change and navigate
    void onToggleChanged(bool value, BuildContext context) {
      isToggled = value;

      // Navigate to a different screen based on toggle value
      if (isToggled) {
        // Use Navigator.push to navigate to FollowupScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FollowupScreen()),
        );
      } else {
        // Pop the current screen if toggled off
        Navigator.pop(context);
      }
    }

    return Switch(
      value: isToggled,
      onChanged: (value) {
        onToggleChanged(value, context); // Navigate on toggle change
      },
      // Remove any border styling here
      activeTrackColor: Colors.white,  // Optional: Set the active track color
      activeColor: Colors.green,      // Optional: Set the active color
      inactiveTrackColor: Colors.grey, // Optional: Set the inactive track color
      inactiveThumbColor: Colors.white,);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Row(
          children: [
            Text(
              'Entries',
              style: TextStyle(
                fontSize: 20,  // Reduced font size to fit better
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(width: 20,),
            Text('Entries',style: TextStyle(fontSize: 12,fontFamily: 'Poppins',fontWeight: FontWeight.bold),),
            Container(
                child: ToggleButtonWithNavigation(context)),
            Text('Follow-ups',style: TextStyle(fontSize: 12,fontFamily: 'Poppins',fontWeight: FontWeight.bold),)
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Container(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: (){}, child: Text("Interested",style: TextStyle(color: Colors.white,fontFamily: 'Poppins'),),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                ),),
                SizedBox(width: 10,),
                TextButton(onPressed: (){}, child: Text("Incomplete",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
                SizedBox(width: 10,),
                TextButton(onPressed: (){}, child: Text("In Progress",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
                SizedBox(width: 10,),
                TextButton(onPressed: (){}, child: Text("Not Answered",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
                SizedBox(width: 10,),
                TextButton(onPressed: (){}, child: Text("Converted",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
                SizedBox(width: 10,),

                TextButton(onPressed: (){}, child: Text("Visited",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
                SizedBox(width: 10,),

                TextButton(onPressed: (){}, child: Text("Rejected",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
                SizedBox(width: 10,),
                TextButton(onPressed: (){}, child: Text("Demo Done",style: TextStyle(color: Colors.white,fontFamily: 'Poppins')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue.shade900, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),),),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
