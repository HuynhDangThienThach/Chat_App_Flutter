import 'package:chatapp/common/entities/entities.dart';
import 'package:chatapp/common/routes/names.dart';
import 'package:chatapp/common/store/store.dart';
import 'package:chatapp/common/widgets/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'index.dart';
import 'package:get/get.dart';


GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes:<String>[
    'openid'
  ]
);


class SignInController extends GetxController{
  final state = SignInState();
  SignInController();
  final db = FirebaseFirestore.instance;
  Future<void> handleSignIn()async {
      try{
        // Thực hiện đăng nhập mới
        var user = await _googleSignIn.signIn();
        // Tiếp tục xử lý đăng nhập và lưu thông tin người dùng
        if(user !=null){
          final _gAuthentication = await user.authentication;
          final _credential = GoogleAuthProvider.credential(
            idToken: _gAuthentication.idToken,
            accessToken: _gAuthentication.accessToken
          );
          await FirebaseAuth.instance.signInWithCredential( _credential);

          String displayName= user.displayName??user.email;
          String email = user.email;
          String id = user.id;
          String photoUrl = user.photoUrl??"";
          //--- Tạo các thuộc tính này để lưu thông tin người dùng;
          UserLoginResponseEntity userProfile = UserLoginResponseEntity();
          userProfile.email = email;
          userProfile.accessToken = id;
          userProfile.displayName = displayName;
          userProfile.photoUrl = photoUrl;

          UserStore.to.saveProfile(userProfile);
          var userbase = await db.collection("users").withConverter(
              fromFirestore: UserData.fromFirestore,
              toFirestore: (UserData userdata, options) => userdata.toFirestore(),
          ).where("id", isEqualTo: id).get();
          if(userbase.docs.isEmpty){
            final data = UserData(
              id: id,
              name: displayName,
              email: email,
              photourl: photoUrl,
              location: "",
              fcmtoken: "",
              addtime: Timestamp.now()
            );
            await db.collection("users").withConverter(
              fromFirestore: UserData.fromFirestore,
              toFirestore: (UserData userdata, options) => userdata.toFirestore(),
            ).add(data);
          }
          toastInfo(msg: "login success");
          Get.offAndToNamed(AppRoutes.Application);
        }
      }catch(e){
        toastInfo(msg: "login error");
        print(e);
      }
  }
  @override
  void onReady(){
    super.onReady();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if(user == null){
        print("User is currently logged out");
      }else{
        print("User is logged in");
      }
    });
  }
}