import { useNavigation } from '@react-navigation/native';
import { useEffect, useState } from 'react';
import {
  Alert,
  Button,
  StyleSheet,
  Text,
  View,
  type EventSubscription,
} from 'react-native';
import { BrightcoveDownloader } from 'react-native-brightcove';
import { accountId, policyKey, videoId } from '../configs';

export function HomeScreen() {
  const navigation = useNavigation();
  const [status, setStatus] = useState('waiting');

  useEffect(() => {
    BrightcoveDownloader.initModule({ accountId, policyKey });

    const listeners: EventSubscription[] = [];
    listeners.push(
      BrightcoveDownloader.onDownloadRequested((e) => {
        console.log('[onDownloadRequested]', e);
        setStatus('requested');
      }),
      BrightcoveDownloader.onDownloadStarted((e) => {
        console.log('[onDownloadStarted]', e);
        setStatus(`started ${e.estimatedSize}`);
      }),
      BrightcoveDownloader.onDownloadProgress((e) => {
        console.log('[onDownloadProgress]', e);
        setStatus(`progress ${e.progress.toFixed(2)}%`);
      }),
      BrightcoveDownloader.onDownloadPaused((e) => {
        console.log('[onDownloadPaused]', e);
        setStatus('paused');
      }),
      BrightcoveDownloader.onDownloadCompleted((e) => {
        console.log('[onDownloadCompleted]', e);
        setStatus('completed');
      }),
      BrightcoveDownloader.onDownloadFailed((e) => {
        console.log('[onDownloadFailed]', e);
        setStatus(`failed ${e.reason}`);
      }),
      BrightcoveDownloader.onDownloadCanceled((e) => {
        console.log('[onDownloadCanceled]', e);
        setStatus('canceled');
      }),
      BrightcoveDownloader.onDownloadDeleted((e) => {
        console.log('[onDownloadDeleted]', e);
        setStatus('deleted');
      })
    );

    return () => listeners.forEach((listener) => listener.remove());
  }, []);

  const goToPlayer = () => navigation.navigate('Player');

  const getAllDownloadedVideos = () => {
    BrightcoveDownloader.getAllDownloadedVideos()
      .then((res) => {
        console.log('[getDownloadedVideos OK]', res);
        Alert.alert('All downloaded videos', JSON.stringify(res));
      })
      .catch((e) => console.log('[getDownloadedVideos ERROR]', e));
  };

  const getDownloadedVideosById = () => {
    BrightcoveDownloader.getDownloadedVideoById(videoId)
      .then((res) => {
        console.log('[getDownloadedVideoById OK]', res);
        Alert.alert(`Downloaded video ${videoId}`, JSON.stringify(res));
      })
      .catch((e) => console.log('[getDownloadedVideoById ERROR]', e));
  };

  const estimateDownloadSize = () => {
    BrightcoveDownloader.estimateDownloadSize(videoId)
      .then((size) => {
        console.log('[estimateDownloadSize OK]', size);
        Alert.alert(`Estimate download size ${videoId}`, `${size} bytes`);
      })
      .catch((e) => console.log('[estimateDownloadSize ERROR]', e));
  };

  const downloadVideo = () => {
    BrightcoveDownloader.downloadVideo(videoId);
  };

  const pauseDownloadVideo = () => {
    BrightcoveDownloader.pauseVideoDownload(videoId)
      .then((res) => console.log('[pauseVideoDownload OK]', res))
      .catch((e) => console.log('[pauseVideoDownload ERROR]', e));
  };

  const resumeDownloadVideo = () => {
    BrightcoveDownloader.resumeVideoDownload(videoId)
      .then((res) => console.log('[resumeVideoDownload OK]', res))
      .catch((e) => console.log('[resumeVideoDownload ERROR]', e));
  };

  const cancelDownloadVideo = () => {
    BrightcoveDownloader.cancelVideoDownload(videoId)
      .then((res) => console.log('[cancelVideoDownload OK]', res))
      .catch((e) => console.log('[cancelVideoDownload ERROR]', e));
  };

  const deleteVideo = () => {
    BrightcoveDownloader.deleteVideo(videoId)
      .then((res) => console.log('[deleteVideo OK]', res))
      .catch((e) => console.log('[deleteVideo ERROR]', e));
  };

  return (
    <View style={styles.container}>
      <Text>{`Status: ${status}`}</Text>
      <Button title="Go to player" onPress={goToPlayer} />
      <Button
        title="Get all downloaded videos"
        onPress={getAllDownloadedVideos}
      />
      <Button
        title="Get download video by id"
        onPress={getDownloadedVideosById}
      />
      <Button title="Estimate download size" onPress={estimateDownloadSize} />
      <Button title="Download video" onPress={downloadVideo} />
      <Button title="Pause download video" onPress={pauseDownloadVideo} />
      <Button title="Resume download video" onPress={resumeDownloadVideo} />
      <Button title="Cancel download video" onPress={cancelDownloadVideo} />
      <Button title="Delete video" onPress={deleteVideo} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
});
