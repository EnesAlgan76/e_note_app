
import 'dart:io';
import 'dart:math';
import 'package:circular_menu/circular_menu.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:e_note_app/localNotificationService.dart';
import 'package:e_note_app/models/Remainder.dart';
import 'package:e_note_app/screens/noteMainPage.dart';
import 'package:e_note_app/screens/settingPage.dart';
import 'package:e_note_app/widgets/categoriesPopUpMenu.dart';
import 'package:e_note_app/widgets/noteTodoWidget.dart';
import 'package:e_note_app/widgets/remaindersWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import '../Blocs/Todo/note_bloc.dart';
import '../NoteDatabaseHelper.dart';
import '../SharedPreferencesOperations.dart';
import '../StaticValues.dart';
import '../models/Note.dart';
import '../widgets/favoriteStar.dart';
import '../widgets/imageGridView.dart';
import '../widgets/popUpMenu.dart';


int? selectedCategoryId =-1;

String getCategoryName(int categoryId){
  Map categoryMap = StaticValues.categoryMap;
  var widgetCategory = categoryMap[categoryId]?? "get_allnotes".tr;
  return widgetCategory;

}

class NoteViewPage extends StatefulWidget {
  Note note;
  int? indexOfNote;
  NoteViewPage(this.note, this.indexOfNote);

  @override
  _NoteViewPageState createState() => _NoteViewPageState();
}


class _NoteViewPageState extends State<NoteViewPage> {
  final titleEditTextController = TextEditingController();
  final noteEditTextController = TextEditingController();
  final todoEditTextController = TextEditingController();
  NoteDatabaseHelper notedbHelper = NoteDatabaseHelper();
  late FocusNode noteFocus;
  String? widgetCategory;
  bool isMenuVisible = true;
  late FocusNode todoFocus;
  late final LocalNotificationService service;



  @override
  void dispose() {
    todoFocus.dispose();
    noteFocus.dispose();
    super.dispose();
  }


  @override
  void initState() {
    if(widget.note.noteId != null){
      titleEditTextController.text = widget.note.noteTitle!;
      noteEditTextController.text = widget.note.noteContent!;
    }
    todoFocus = FocusNode();
    noteFocus =FocusNode();
    getPassword();
    service = LocalNotificationService();
    service.initialize();
    super.initState();
  }



  Future<String> saveImageToLocal(bool isGallery)async{
    XFile? imageFile2 =isGallery?
    await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75
    ) :
    await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 50
    );
    if (imageFile2 !=null){
      final Directory duplicateFileDir = await getApplicationDocumentsDirectory();
      String duplicateFilePath = duplicateFileDir.path;
      final fileName = basename(imageFile2.path);
      await imageFile2.saveTo('$duplicateFilePath/$fileName');
      StaticValues.imageStringList.add('$duplicateFilePath/$fileName');
      return '$duplicateFilePath/$fileName';
    }else{
      return "";
    }
  }


  @override
  Widget build(BuildContext context) {
    final noteBloc= BlocProvider.of<NoteBloc>(context);
    final bool showFab = MediaQuery.of(context).viewInsets.bottom==0.0;

    return SafeArea(
      child:WillPopScope(
        onWillPop: ()async{
          String color = StaticValues.colorList[StaticValues.lastNoteId%6];
          if(widget.note.noteId == null ){
            if((noteEditTextController.text !="" || titleEditTextController.text !="") || StaticValues.imageStringList.length>0 || getxController.todoMap.isNotEmpty){

              Note note =  Note(
                noteTitle: titleEditTextController.text,
                noteContent: noteEditTextController.text,
                noteColor: color,
                noteCategoryId: selectedCategoryId,
                imageList: {},
                isLocked: StaticValues.lockstate,
              );
              selectedCategoryId =-1;

              int noteId = await notedbHelper.insertNote(note);
              await notedbHelper.insertImage(noteId, StaticValues.imageStringList);
              await notedbHelper.insertTodo(noteId, getxController.todoMap);
              getxController.todoMap.value={};
              if(getxController.newNoteRemainders.isNotEmpty){
                for(String date in getxController.newNoteRemainders){
                  int id =await notedbHelper.insertRemainder(Remainder(id: null, noteId: noteId, date: date));
                  await service.showScheduledNotification(id: id,title: widget.note.noteTitle??"E Notes",
                      body: widget.note.noteContent==null?"": (widget.note.noteContent!.length>100 ? widget.note.noteContent!.substring(0,100):widget.note.noteContent!),
                      dateTime: DateTime.parse(date));}
                  }
            }

          }else{
            notedbHelper.updateNoteContent(widget.note.noteId!, noteEditTextController.text);
            notedbHelper.updateNoteTitle(widget.note.noteId!, titleEditTextController.text);
            if(selectedCategoryId != null){
              notedbHelper.updateNoteCategory(widget.note.noteId!, selectedCategoryId!);
            }
            notedbHelper.updateIsLocked(widget.note.noteId!, StaticValues.lockstate);
          }
          selectedCategoryId =-1;
          StaticValues.currentCategoryName= "get_allnotes".tr;
          StaticValues.imageStringList.clear();
          noteBloc.add(StaticValues.currentEvent);
          getxController.addingTask.value=false;
          Navigator.pop(context);

          return true;
        },
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Container(height: 60, color: const Color(0xfcdcdcd),
                    child: Row(
                      children: [
                        IconButton(
                            onPressed:() async {
                              String color = StaticValues.colorList[StaticValues.lastNoteId%6];
                              if(widget.note.noteId == null ){
                                if((noteEditTextController.text !="" || titleEditTextController.text !="") || StaticValues.imageStringList.length>0 || getxController.todoMap.isNotEmpty){

                                  Note note =  Note(
                                      noteTitle: titleEditTextController.text,
                                      noteContent: noteEditTextController.text,
                                      noteColor: color,
                                      noteCategoryId: selectedCategoryId,
                                      imageList: {},
                                      isLocked: StaticValues.lockstate,
                                  );
                                  selectedCategoryId =-1;

                                  int noteId = await notedbHelper.insertNote(note);
                                  await notedbHelper.insertImage(noteId, StaticValues.imageStringList);
                                  await notedbHelper.insertTodo(noteId, getxController.todoMap);
                                  getxController.todoMap.value={};

                                  if(getxController.newNoteRemainders.isNotEmpty){
                                    for(String date in getxController.newNoteRemainders){
                                      int id =await notedbHelper.insertRemainder(Remainder(id: null, noteId: noteId, date: date));
                                      await service.showScheduledNotification(id: id,title: widget.note.noteTitle??"E Notes",
                                          body: widget.note.noteContent==null?"": (widget.note.noteContent!.length>100 ? widget.note.noteContent!.substring(0,100):widget.note.noteContent!),
                                          dateTime: DateTime.parse(date)
                                      );
                                    }
                                  }
                                }else{
                                  Get.snackbar("get_blanknotedelted".tr, "".tr, backgroundColor: Color(0x888d0038),colorText: Colors.white, duration: Duration(milliseconds: 1500));
                                }

                              }else{
                                notedbHelper.updateNoteContent(widget.note.noteId!, noteEditTextController.text);
                                notedbHelper.updateNoteTitle(widget.note.noteId!, titleEditTextController.text);
                                if(selectedCategoryId != null){
                                  notedbHelper.updateNoteCategory(widget.note.noteId!, selectedCategoryId!);
                                }
                                notedbHelper.updateIsLocked(widget.note.noteId!, StaticValues.lockstate);
                              }
                              selectedCategoryId =-1;
                              StaticValues.currentCategoryName= "get_allnotes".tr;
                              StaticValues.imageStringList.clear();
                              noteBloc.add(StaticValues.currentEvent);
                              getxController.addingTask.value=false;
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.done_outline_rounded, color: Color(0xff006c8d),)
                        ),
                        CategoriesPopUpMenu(),
                        Spacer(),
                        FavoriteStar(widget.indexOfNote==null ?-1:widget.indexOfNote!),
                        EnesPopUpMenu(lockState: widget.note.isLocked,noteId: widget.note.noteId,)



                      ],
                    ),
                  ), //Back Icon



                   Expanded(
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Get.isDarkMode? Color(0xff454545): Color(0xfff3f3f3)),
                        margin: EdgeInsets.only(left: 10,right: 10),
                        padding: EdgeInsets.all(10),
                        child: ListView(
                          children:  [
                            TextField(
                              onTap: (){
                                setState(() {
                                  isMenuVisible=false;
                                });
                              },
                              controller: titleEditTextController,
                              style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Get.isDarkMode? Colors.white: Colors.black, fontFamily: 'Quicksand',),
                              decoration: InputDecoration(border: InputBorder.none, hintText:"get_title".tr),
                              onSubmitted: (value){
                                noteFocus.requestFocus();
                              },
                            ),
                            if(widget.indexOfNote != null)
                            remaindersWidget(noteId: widget.note.noteId!),
                            if(widget.indexOfNote == null)
                            remaindersWidget(),


                            if(widget.indexOfNote != null)
                            ImageGridWidget(indexOfNote: widget.indexOfNote!),
                            if(widget.indexOfNote == null)//
                            ImageGridWidget(),// IMAGES


                            Obx((){
                              if(getxController.addingTask.value==true){
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10,left: 10,right: 10),
                                  child: SizedBox(
                                    height: 35,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            focusNode: todoFocus,
                                            controller: todoEditTextController,
                                            onSubmitted: (value)async {
                                              if(widget.indexOfNote==null){
                                                getxController.todoMap["${value}"] =0;
                                              }else{
                                                await notedbHelper.insertTodo(widget.note.noteId!, {"${value}":0});
                                                noteBloc.add(StaticValues.currentEvent);
                                              }
                                              todoEditTextController.text="";
                                              todoFocus.requestFocus();
                                              },
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.all(10),
                                              hintText: "get_entertodo??tem".tr,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                            onPressed: (){
                                              getxController.addingTask.value =false;
                                            },
                                            icon: Icon(Icons.close_rounded,size: 20,color: Colors.black54,))
                                      ],
                                    ),
                                  ),
                                );
                              }else{
                                return Container();
                              }
                            }),

                            if(widget.indexOfNote != null)
                            noteTodoWidget(indexOfNote: widget.indexOfNote,),
                            if(widget.indexOfNote == null)
                            noteTodoWidget(),


                            TextField(
                              onTap: (){
                                setState(() {
                                  isMenuVisible=false;
                                });
                              },
                              maxLines: null,
                                focusNode: noteFocus,
                                controller: noteEditTextController,
                                style:  TextStyle(fontSize: fontSize.toDouble(), color: Get.isDarkMode? Color(0xfff8f8f8) : Colors.black,fontFamily: 'Quicksand',),
                                decoration:  InputDecoration(border: InputBorder.none, hintText: "get_note".tr),

                              ),
                            SizedBox(height: 200,)
],
                        ),
                      ),
                    ),
                ],
              ),
              //EnesDropDown(value: getCategoryName(widget.note.noteCategoryId??-1) ),


            ],
          ),



              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: showFab? CircularMenu(
                    toggleButtonAnimatedIconData: AnimatedIcons.menu_close,
                    alignment: Alignment.bottomLeft,
                    toggleButtonColor: Color(0xff006c8d),
                    toggleButtonSize: 25,
                    toggleButtonMargin: 20,
                    toggleButtonPadding: 13,
                    startingAngleInRadian:  pi*1.50,
                    endingAngleInRadian: pi*1.99,
                    radius: 100,
                    toggleButtonBoxShadow: [],

                    items: [
                      CircularMenuItem(
                          color: Color(0xff595959),
                          iconSize: 20,
                          boxShadow: [],
                          icon: Icons.photo,
                          onTap: (){
                            if(widget.note.noteId==null){
                              saveImageToLocal(true).then((value){
                                setState(() {});
                              });
                            }else{
                              saveImageToLocal(true).then((value) async {
                                await notedbHelper.insertImage(widget.note.noteId!, [value]);
                                noteBloc.add(StaticValues.currentEvent);
                              });
                            }

                          }),
                      CircularMenuItem(
                        color: Color(0xff207178),
                        icon: Icons.camera_alt_rounded,
                        iconSize: 20,
                        boxShadow: [],
                        onTap: (){
                          if(widget.note.noteId==null){
                            saveImageToLocal(false).then((value){
                              setState(() {});
                            });
                          }else{
                            saveImageToLocal(false).then((value) async {
                              await notedbHelper.insertImage(widget.note.noteId!, [value]);
                              noteBloc.add(StaticValues.currentEvent);
                            });
                          }

                        },
                      ),

                      CircularMenuItem(
                          color: Color(0xfffdc701),
                          icon: Icons.alarm_add_rounded,
                          iconSize: 20,
                          boxShadow: [],
                          onTap: ()async {
                            late DateTime selectedDate;
                            bool hasDateSelected=false;
                            Alert(
                                context: context,
                                title: "Hat??rlat??c?? Ekle",
                                content: Column(
                                  children: <Widget>[
                                    Obx((){
                                      if(getxController.hasDatePast==true){
                                        return Text("Se??ti??in zaman ge??ti zaten",style: TextStyle(fontSize: 16,color: Colors.red),);
                                      }else{
                                        return Container();
                                      }
                                    }),
                                    DateTimePicker(
                                      type: DateTimePickerType.dateTimeSeparate,
                                      dateMask: 'd MMM, yyyy',
                                      initialValue: DateTime.now().toString(),
                                      firstDate: DateTime(DateTime.now().year),
                                      lastDate: DateTime(DateTime.now().year+17),
                                      icon: Icon(Icons.event),
                                      dateLabelText: 'Date',
                                      timeLabelText: "Hour",
                                      onChanged: (val) {
                                       if(DateTime.parse(val).isBefore(DateTime.now())){
                                          print("eski tarih");
                                          getxController.hasDatePast.value =true;
                                        }else{
                                          getxController.hasDatePast.value =false;
                                        }
                                        selectedDate =DateTime.parse(val);
                                       hasDateSelected =true;
                                        },

                                    )
                                  ],
                                ),
                                buttons: [
                                  DialogButton(
                                    onPressed: () async{
                                      if(hasDateSelected ==true && getxController.hasDatePast==false){
                                        if(widget.indexOfNote!=null){
                                          int id =await notedbHelper.insertRemainder(Remainder(id: null, noteId: widget.note.noteId!, date: selectedDate.toString()));
                                          await service.showScheduledNotification(id: id,title: widget.note.noteTitle??"E Notes",
                                              body: widget.note.noteContent==null?"": (widget.note.noteContent!.length>100 ? widget.note.noteContent!.substring(0,100):widget.note.noteContent!),
                                              dateTime: selectedDate
                                          );
                                          getxController.getxGetRemainders(widget.note.noteId!);
                                          Navigator.pop(context);
                                          Get.snackbar("get_remaindercreated".tr,"", backgroundColor: Color(0x88006c8d),colorText: Colors.white, duration: Duration(milliseconds: 1500));

                                        }else{
                                          Navigator.pop(context);
                                          getxController.newNoteRemainders.add(selectedDate.toString());
                                        }
                                      }else{
                                        Get.snackbar("get_remaindernotcreated".tr, "get_youselectedpastdate".tr, backgroundColor: Color(0x88006c8d),colorText: Colors.white, duration: Duration(milliseconds: 1500));
                                      }

                                      },
                                    child: Text(
                                      "get_add".tr,
                                      style: TextStyle(color: Colors.white, fontSize: 20),
                                    ),
                                    color: Color(0xff006c8d),
                                  )
                                ]).show();
                           }),



                      CircularMenuItem(
                          color: Color(0xff9c0757),
                          icon: Icons.check_circle_outline_rounded,
                          iconSize: 20,
                          boxShadow: [],
                          onTap: () {
                            getxController.addingTask.value =true;
                          }),
                    ]):null,
              ),
      ),
    );
  }


}






