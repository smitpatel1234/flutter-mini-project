import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/user_wonder_model.dart';
import '../services/wonder_service.dart';
import 'user_wonder_page.dart';

class PersonalWondersPage extends StatefulWidget {
  const PersonalWondersPage({Key? key}) : super(key: key);

  @override
  _PersonalWondersPageState createState() => _PersonalWondersPageState();
}

class _PersonalWondersPageState extends State<PersonalWondersPage> {
  final WonderService _wonderService = WonderService();
  String _searchQuery = '';
  String _filterOption = 'All';
  final List<String> _filterOptions = [
    'All',
    'Visited',
    'Planned',
    'Recent',
    'Oldest',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wonder Collection'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.cyanAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.cyan.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search your wonders...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),

                // Filter chips
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _filterOptions.map((option) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(option),
                              selected: _filterOption == option,
                              onSelected: (selected) {
                                setState(() {
                                  _filterOption = selected ? option : 'All';
                                });
                              },
                              avatar:
                                  option == 'Visited'
                                      ? Icon(Icons.check_circle, size: 18)
                                      : option == 'Planned'
                                      ? Icon(Icons.calendar_today, size: 18)
                                      : option == 'Recent'
                                      ? Icon(Icons.access_time, size: 18)
                                      : option == 'Oldest'
                                      ? Icon(Icons.history, size: 18)
                                      : Icon(Icons.filter_list, size: 18),
                              backgroundColor: Colors.white,
                              selectedColor: Colors.blue.withOpacity(0.2),
                              checkmarkColor: Colors.blue,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Wonders list
          Expanded(
            child: StreamBuilder<List<UserWonderModel>>(
              stream: _wonderService.getUserWonders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading wonders: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final wonders = snapshot.data ?? [];

                if (wonders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tour, size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No wonders yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start adding personal wonders\nto your collection',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserWonderPage(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add Your First Wonder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Apply search filter
                var filteredWonders =
                    wonders.where((wonder) {
                      bool matchesSearch =
                          _searchQuery.isEmpty ||
                          wonder.name.toLowerCase().contains(_searchQuery) ||
                          (wonder.description.toLowerCase().contains(
                            _searchQuery,
                          )) ||
                          (wonder.location?.toLowerCase().contains(
                                _searchQuery,
                              ) ??
                              false);

                      // Apply category filter
                      switch (_filterOption) {
                        case 'Visited':
                          return matchesSearch && wonder.isCompleted;
                        case 'Planned':
                          return matchesSearch &&
                              wonder.plannedVisitDate != null &&
                              !wonder.isCompleted;
                        case 'Recent':
                          // Sort by created date is handled below
                          return matchesSearch;
                        case 'Oldest':
                          // Sort by created date is handled below
                          return matchesSearch;
                        case 'All':
                        default:
                          return matchesSearch;
                      }
                    }).toList();

                // Sort based on filter
                if (_filterOption == 'Recent') {
                  filteredWonders.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );
                } else if (_filterOption == 'Oldest') {
                  filteredWonders.sort(
                    (a, b) => a.createdAt.compareTo(b.createdAt),
                  );
                }

                if (filteredWonders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No matches found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try different search terms or filters',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Display wonders in a grid
                return Padding(
                  padding: EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredWonders.length,
                    itemBuilder: (context, index) {
                      final wonder = filteredWonders[index];
                      return _buildWonderCard(wonder);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserWonderPage()),
          ).then((_) => setState(() {}));
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildWonderCard(UserWonderModel wonder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserWonderPage(wonderId: wonder.id),
          ),
        ).then((_) => setState(() {}));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (wonder.imageUrl != null)
              CachedNetworkImage(
                imageUrl: wonder.imageUrl!,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.blue[100],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.blue[800],
                      ),
                    ),
              )
            else
              Container(
                color: Colors.blue[100],
                child: Icon(
                  Icons.photo_album,
                  size: 40,
                  color: Colors.blue[800],
                ),
              ),

            // Info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wonder.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (wonder.location != null && wonder.location!.isNotEmpty)
                      Text(
                        wonder.location!,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (wonder.plannedVisitDate != null)
                      Text(
                        DateFormat(
                          'MMM d, yyyy',
                        ).format(wonder.plannedVisitDate!),
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),

            // Status badge
            if (wonder.isCompleted)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "Visited",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
