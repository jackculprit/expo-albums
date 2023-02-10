import 'expo-dev-client';
import * as Settings from 'expo-albums';
import { Image, Text, View, ScrollView, FlatList } from "react-native";
import { useEffect, useState } from "react";

export default function App() {
  const [imageUrls, setImageUrls] = useState([])
  const asyncFunc = async () => {
    try {
      var startTime = performance.now()
      const test = await Settings.getTheme();
      var endTime = performance.now()
      console.log(`Call to doSomething took ${endTime - startTime} milliseconds`)
      console.log('test', test.auth.length)
      setImageUrls(test.auth)
    } catch (e) {
      console.log('e', e)
    }
  }

  useEffect(() => {
    asyncFunc()
  }, [])

  const renderItem = ({item, index}) => {
    return (
        <Image source={{uri: item}} style={{height: 100, width: 100}} />
    )
  }

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Text>Theme</Text>
      {imageUrls && (
        <FlatList numColumns={3} data={imageUrls} renderItem={renderItem} />
      )}
    </View>
  );
}
