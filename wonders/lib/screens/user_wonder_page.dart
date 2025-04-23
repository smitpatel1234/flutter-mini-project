import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_wonder_model.dart';
import '../services/wonder_service.dart';

class UserWonderPage extends StatefulWidget {
  final String? wonderId;

  const UserWonderPage({Key? key, this.wonderId}) : super(key: key);

  @override
  _UserWonderPageState createState() => _UserWonderPageState();
}

class _UserWonderPageState extends State<UserWonderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isImageLoading = false;
  double? _latitude;
  double? _longitude;
  DateTime? _plannedDate;
  bool _isCompleted = false;
  DateTime? _completedDate;

  late WonderService _wonderService;
  UserWonderModel? _existingWonder;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _wonderService = WonderService();
    _loadExistingWonder();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadExistingWonder() async {
    if (widget.wonderId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final wonder = await _wonderService.getUserWonder(widget.wonderId!);
        if (wonder != null && mounted) {
          setState(() {
            _existingWonder = wonder;
            _nameController.text = wonder.name;
            _descriptionController.text = wonder.description;
            _locationController.text = wonder.location ?? '';
            _currentImageUrl = wonder.imageUrl;
            _plannedDate = wonder.plannedVisitDate;
            _latitude = wonder.latitude;
            _longitude = wonder.longitude;
            _isCompleted = wonder.isCompleted;
            _completedDate = wonder.completedDate;
          });
        }
      } catch (e) {
        _showErrorSnackBar('Error loading wonder: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: Duration(seconds: 6),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isImageLoading = true;
        _imageError = null;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Check file size (limit to 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _imageError = 'Image is too large (max 5MB)';
            _isImageLoading = false;
          });
          return;
        }

        setState(() {
          _imageFile = file;
          _isImageLoading = false;
        });
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _imageError = 'Error selecting image: $e';
        _isImageLoading = false;
      });
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isImageLoading = true;
        _imageError = null;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isImageLoading = false;
        });
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _imageError = 'Error taking photo: $e';
        _isImageLoading = false;
      });
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  void _showImageOptions() {
    // Don't show if already loading
    if (_isImageLoading) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.blue),
                  title: Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue),
                  title: Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                if (_imageFile != null || _currentImageUrl != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      'Remove Image',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                        _currentImageUrl = null;
                        _imageError = null;
                      });
                    },
                  ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate ?? DateTime.now(),
      firstDate: DateTime(2000), // Allow historical dates
      lastDate: DateTime(2100),
      helpText: 'Select planned visit date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _plannedDate) {
      setState(() {
        _plannedDate = picked;
      });
    }
  }

  // Location selection
  void _selectLocation() {
    showDialog(
      context: context,
      builder: (context) {
        String locationName = _locationController.text;
        double? lat = _latitude;
        double? lng = _longitude;

        return AlertDialog(
          title: Text('Enter Location Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g. Great Wall of China',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => locationName = value,
                  controller: TextEditingController(text: locationName),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Latitude (optional)',
                    hintText: 'e.g. 40.4319',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.my_location),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => lat = double.tryParse(value),
                  controller: TextEditingController(
                    text: lat?.toString() ?? '',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Longitude (optional)',
                    hintText: 'e.g. 116.5704',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.my_location),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => lng = double.tryParse(value),
                  controller: TextEditingController(
                    text: lng?.toString() ?? '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _locationController.text = locationName;
                  _latitude = lat;
                  _longitude = lng;
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWonder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text(
                _imageFile != null ? 'Uploading image...' : 'Saving wonder...',
              ),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      if (_existingWonder == null) {
        // Create new wonder
        await _wonderService.createWonder(
          name: _nameController.text,
          description: _descriptionController.text,
          imageFile: _imageFile,
          location: _locationController.text,
          latitude: _latitude,
          longitude: _longitude,
          plannedVisitDate: _plannedDate,
        );
      } else {
        // Update existing wonder
        await _wonderService.updateWonder(
          wonderId: _existingWonder!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          imageFile: _imageFile,
          location: _locationController.text,
          latitude: _latitude,
          longitude: _longitude,
          plannedVisitDate: _plannedDate,
          isCompleted: _isCompleted,
        );
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wonder saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving wonder: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            onPressed: _saveWonder,
            textColor: Colors.white,
          ),
          duration: Duration(seconds: 10),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteWonder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Wonder'),
            content: Text(
              'Are you sure you want to delete this wonder? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true && _existingWonder != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _wonderService.deleteWonder(_existingWonder!.id);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Wonder deleted successfully')));

        Navigator.pop(context, true); // Return true to refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting wonder: $e'),
            backgroundColor: Colors.red,
          ),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Build image section with proper error handling
  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            _isImageLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Processing image...'),
                    ],
                  ),
                )
                : _imageError != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40),
                      SizedBox(height: 8),
                      Text(
                        _imageError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: _showImageOptions,
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                )
                : _imageFile != null
                ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        color: Colors.black38,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Tap to change image',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
                : _currentImageUrl != null
                ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _currentImageUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Center(child: CircularProgressIndicator()),
                        errorWidget:
                            (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Force cache refresh
                                    CachedNetworkImage.evictFromCache(
                                      _currentImageUrl!,
                                    );
                                    setState(() {});
                                  },
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                        cacheKey:
                            'wonder-${widget.wonderId}', // Cache key for better control
                        maxHeightDiskCache: 800,
                        memCacheHeight: 800,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        color: Colors.black38,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Tap to change image',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to add an image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingWonder == null ? 'Create Your Wonder' : 'Edit Your Wonder',
        ),
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
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image section
                      _buildImageSection(),

                      SizedBox(height: 20),

                      // Wonder name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Wonder Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name for your wonder';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please describe your wonder';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Location
                      GestureDetector(
                        onTap: _selectLocation,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                              suffixIcon: Icon(Icons.edit_location),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Planned date
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'When do you want to visit?',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text:
                                  _plannedDate == null
                                      ? ''
                                      : DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_plannedDate!),
                            ),
                          ),
                        ),
                      ),

                      // Completion status for existing wonders
                      if (_existingWonder != null) ...[
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Have you visited this wonder?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Switch(
                                    value: _isCompleted,
                                    onChanged: (value) {
                                      setState(() {
                                        _isCompleted = value;
                                        if (value && _completedDate == null) {
                                          _completedDate = DateTime.now();
                                        }
                                      });
                                    },
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                              if (_isCompleted && _completedDate != null) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Visited on: ${DateFormat('MMM dd, yyyy').format(_completedDate!)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 30),

                      // Save button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveWonder,
                        icon: Icon(
                          _existingWonder == null
                              ? Icons.add_circle
                              : Icons.save,
                        ),
                        label: Text(
                          _existingWonder == null
                              ? 'Create Wonder'
                              : 'Update Wonder',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Delete button for existing wonders
                      if (_existingWonder != null) ...[
                        SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _deleteWonder,
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text('Delete Wonder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
