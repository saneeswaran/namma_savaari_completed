// bus_booking_application

import 'package:animate_do/animate_do.dart';
import 'package:bus_booking_app/customer/theme_provider.dart';
import 'package:bus_booking_app/customer/view_more_shorts_screen.dart';
import 'package:bus_booking_app/customer/view_more_youtube_videos_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'Account_settings_screen.dart';
import 'balance_api_screen.dart';
import 'balance_log_api_screen.dart';
import 'cancel_ticket_screen.dart';
import 'customer_all_offers_list_screen.dart';
import 'help_screen.dart';

class MyAccountScreen extends StatefulWidget {
  final VoidCallback onNavigateToHelp;
  final VoidCallback onNavigateToBookings;

  const MyAccountScreen({
    required this.onNavigateToHelp,
    required this.onNavigateToBookings,
    Key? key,
  }) : super(key: key);

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {

  String selectedCountry = 'India';

  // Method to show the rating dialog
  Future<void> _showRateDialog(BuildContext context) async {
    final TextEditingController _reviewController = TextEditingController();
    double _rating = 0.0; // Variable to store the user's rating

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.all(16.0),
            content: Container(
              height: MediaQuery.of(context).size.height * 0.45, // Adjusted height
              width: MediaQuery.of(context).size.width * 0.9, // Adjusted width
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image on top
                    FadeInDown(
                      duration: Duration(milliseconds: 500),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.asset(
                          'assets/rate_rev.JPG', // Replace with your asset image
                          height: 180, // Updated image height
                          width: double.infinity, // Updated image width
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // "Rate Your Experience" Text
                    FadeIn(
                      duration: Duration(milliseconds: 500),
                      child: Text(
                        "Rate Your Experience",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Mandatory Rating input (stars)
                    FadeIn(
                      duration: Duration(milliseconds: 500),
                      child: RatingBar.builder(
                        initialRating: _rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        unratedColor: Colors.grey, // Color for unselected stars
                        onRatingUpdate: (rating) {
                          _rating = rating;
                        },
                      ),
                    ),
                    SizedBox(height: 10),

                    // Optional Review input
                    FadeInUp(
                      duration: Duration(milliseconds: 500),
                      child: TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write a review (Optional)...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16), // Adjust padding for buttons
            actionsAlignment: MainAxisAlignment.spaceBetween, // Arrange buttons properly
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                ),
                onPressed: () async {
                  if (_rating == 0.0) {
                    // Show a message if rating is not provided
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please provide a rating!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Get the logged-in user's ID
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    String uid = user.uid; // Customer UID
                    String review = _reviewController.text;

                    try {
                      // Check if the user has already submitted a rating
                      var reviewSnapshot = await FirebaseFirestore.instance
                          .collection('customers')
                          .doc(uid)
                          .collection('reviews')
                          .limit(1) // Limit to one review per customer
                          .get();

                      if (reviewSnapshot.docs.isNotEmpty) {
                        // Update the existing review
                        await FirebaseFirestore.instance
                            .collection('customers')
                            .doc(uid)
                            .collection('reviews')
                            .doc(reviewSnapshot.docs[0].id)
                            .update({
                          'rating': _rating,
                          'review': review.isNotEmpty ? review : null,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rating updated successfully!'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      } else {
                        // Add a new review
                        await FirebaseFirestore.instance
                            .collection('customers')
                            .doc(uid)
                            .collection('reviews')
                            .add({
                          'rating': _rating,
                          'review': review.isNotEmpty ? review : null,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rating submitted successfully!'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit rating: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }

                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showCountryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Country',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Image.asset(
                  'assets/Flag_of_India.svg.png', // Replace with the correct path to your image
                  width: 30,
                  height: 30,
                ),
                title: Text('India',style: TextStyle(fontSize: 16,),),
                onTap: () {
                  setState(() {
                    selectedCountry = 'India';
                  });
                  Navigator.pop(context); // Close the bottom sheet after selecting
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchCustomerDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();
        return snapshot.data() as Map<String, dynamic>;
      } catch (e) {
        print('Error fetching customer details: $e');
        return {};
      }
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchCustomerDetails(),
        builder: (context, snapshot) {


          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   // Custom loading indicator with animation
          //   return Center(
          //     child: FadeIn(
          //       duration: Duration(milliseconds: 300),
          //       child: CircularProgressIndicator(
          //         valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          //         strokeWidth: 6.0,
          //       ),
          //     ),
          //   );
          // }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent.shade700),
              minHeight: 5.0,
            );
          }


          Map<String, dynamic>? data = snapshot.data;
          String name = data?['name'] ?? '';
          String email = data?['email'] ?? '';
          Timestamp? createdAt = data?['createdAt'];
          String createdAtString = createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(createdAt.millisecondsSinceEpoch).toLocal().toString()
              : '';

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      child: Image.asset(
                        'assets/customer_profile.jpg',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (name.isNotEmpty)
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          if (createdAtString.isNotEmpty)
                            Text(
                              'Member since $createdAtString',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30,),
                      Text(
                        'My details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20,),
                      ListTile(
                        leading: Icon(Icons.book, color: Colors.redAccent.shade700),
                        title: Text('Bookings', style: TextStyle(fontSize: 18)),
                        onTap: widget.onNavigateToBookings, // Navigate to Bookings tab
                      ),
                      SizedBox(height: 20,),
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20,),
                      ListTile(
                        leading: Icon(Icons.local_offer, color: Colors.redAccent.shade700),
                        title: Text('Offers',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Navigate to the Offers screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerAllOffersListScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.ondemand_video_rounded, color: Colors.redAccent.shade700),
                        title: Text('Trending videos',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Navigate to the Offers screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewMorePage(),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.video_library, color: Colors.redAccent.shade700),
                        title: Text('Trending shorts',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Navigate to the Offers screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewMoreShortsScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.account_balance_wallet, color: Colors.redAccent.shade700),
                        title: Text('Balance',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Navigate to the Offers screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BalanceScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.account_balance, color: Colors.redAccent.shade700),
                        title: Text('Wallet History',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Navigate to the Offers screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BalanceLogScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(),

                      ListTile(
                        leading: Icon(Icons.star_rate, color: Colors.redAccent.shade700),
                        title: Text('Rate app',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Show the rating dialog
                          _showRateDialog(context); // Call the rating dialog function
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.help, color: Colors.redAccent.shade700),
                        title: Text('Help', style: TextStyle(fontSize: 18)),
                        onTap: widget.onNavigateToHelp, // Navigate to Help tab
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.manage_accounts_outlined, color: Colors.redAccent.shade700),
                        title: Text('Account settings',style: TextStyle(fontSize: 18),),
                        onTap: () {
                          // Navigate to the Offers screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20,),
                      Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20,),
                      ListTile(
                        leading: Image.asset(
                          'assets/Flag_of_India.svg.png', // Replace with the correct path to your image
                          width: 30,
                          height: 30,
                        ),
                        title: Text('Country',style: TextStyle(fontSize: 18),),
                        subtitle: Text(selectedCountry),
                        onTap: () {
                          showCountryBottomSheet(context);
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.currency_rupee, color: Colors.redAccent.shade700), // Leading star icon
                        title: Row(
                          children: [
                            Text('Currency',style: TextStyle(fontSize: 18),), // Currency title
                            SizedBox(width: 8),
                          ],
                        ),
                        subtitle: Text('INR',style: TextStyle(fontSize: 16,),), // Display "INR" below the currency title
                        onTap: () {
                          // You can add any action here if needed, or leave it empty.
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.language, color: Colors.redAccent.shade700),
                        title: Text('Language',style: TextStyle(fontSize: 18,),),
                        onTap: () {
                          // // Navigate to the Help screen
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => HelpScreen(),
                          //   ),
                          // );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.brightness_2, color: Colors.redAccent.shade700),
                        // leading: Icon(Icons.wb_sunny, color: Colors.pink),
                        title: Text('Dark Mode'),
                        trailing: Switch(
                          value: Provider.of<ThemeProvider>(context).isDarkMode,
                          onChanged: (value) {
                            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      )
    );
  }
}

