import ddf.minim.*; // importing sound library
import processing.serial.*; // Comunicação com o Arduino

Minim minim;
Serial myPort; // Communication channel with the Arduino
AudioInput in; // O "ouvido" (our microphone) (Processing.org)
AudioRecorder recorder; // Converts the sound into digital data (Processing.org)

int maxVox= 10; // maximum of voices playing simultaneously
ArrayList<String> recordNameStorage = new ArrayList<String>(); // Saves the name of each record
ArrayList<AudioPlayer> soundStorage = new ArrayList<AudioPlayer>(); // Sound storage; we don't delete any records

int currentRecordNumber = 0; // tracks the current record for labelling
boolean weAreRecording = false;

// Variáveis para o intervalo de tempo entre loops
int pause = 2000; // 2 segundos
int[] tempoProximaReproducao = new int[maxVox]; // tabela de horas para sabermos quando cada slot deve tocar

void setup(){
  
  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO, 512); // mono is a lighter file
  
  String portName = Serial.list()[0]; // building the name of the channel through which we are going to communicate with the Arduino
  // Serial.list() takes a look at all devices connected through USB
  // [0] chooses the first device on the list. If it's not working we can try changing this number
  myPort = new Serial(this, portName, 9600); // Establishing the connection with the Arduino ("this"= this Processing file)
  myPort.bufferUntil('\n'); // This is so Processing waits until the end of the Arduino's messages before it starts processing them

}

void draw (){
  int currentTime = millis();
  
  for (int i = 0; i < soundStorage.size(); i++) {
    AudioPlayer player = soundStorage.get(i);
    
    if (player != null) {
      if (!player.isPlaying() && currentTime > tempoProximaReproducao[i]) {
        // se não está a tocar nada e já passou o tempo de pausa
        player.rewind(); 
        player.play();
      } 
      // Se o record já acabou de tocar e 
      //Se a música chegou ao fim e ainda não agendámos a próxima vez -> Agenda!
      else if (player.position() >= player.length() - 50 && tempoProximaReproducao[i] < currentTime) {
        // Próximo arranque = Agora + 2 segundos de pausa
        tempoProximaReproducao[i] = currentTime + pause;
      }
    }
  }
}

void serialEvent (Serial myPort){ // Checks for Arduino activity and processes it
//Is necessary because the void draw runs fast and the Arduino is slow

// Reading the message
  String message = myPort.readStringUntil('\n'); // We read the message from the Arduino
  if (message != null) { 
    // Por vezes a comunicação falha e a mensagem vem vazia, o que faz o Processing crashar.
    // Este if evita que o programa vá a baixo.
    message = trim(message); // Limpa os espaços vazios e informação adicional desnecessária do Arduino
  
    if (message.equals("Record") && !weAreRecording){ // checking if the Arduino told us to record
      weAreRecording = true;
      
      // Silencing the choir
      for (AudioPlayer player : soundStorage) { // we go through all our sound files
        if (player != null) {
          player.close(); // and shut them up
        }
      }
      soundStorage.clear();
      
      String recordName = "voice" + currentRecordNumber + ".wav"; // Creating the record name
      recordNameStorage.add(recordName); // Assigning the name to the current voice recording
  
      // Turn on the microphone and start recording:
      recorder = minim.createRecorder(in, recordName); 
      recorder.beginRecord();
      println("Recording: " + recordName);
    }
    
    else if (message.equals("Stop Recording") && weAreRecording){ // quando paramos a gravação
      weAreRecording = false; // atualizar a booleana
      recorder.endRecord(); // parar a gravação
      recorder.save(); // guardar o record no nosso array
      println("Record Saved in Sound Storage");
      currentRecordNumber ++;
      
      updateChoir();
    }
  }
}

void updateChoir() {
  
  for (AudioPlayer player : soundStorage) { // we go through all the recordings
    if (player != null) { // checking if there are any recordings left
      player.close(); // we stop all the recordings
    }
  }
  soundStorage.clear();
  
  int totalOfVoices = recordNameStorage.size();
  int currentTime = millis();
  
  if (totalOfVoices <= maxVox) { // if don't have any excess voices yet
    for (int i = 0; i < totalOfVoices; i++) {
      AudioPlayer player = minim.loadFile(recordNameStorage.get(i)); // We load all the voice records to a player
      soundStorage.add(player);
    }
  } else{
    float[] prob = new float[totalOfVoices]; // probabilidade de um record tocar
    for (int i=0; i<totalOfVoices; i++){
      //prob = recordNumber * random (0,1); // a probabilidade é maior se o record for mais recente
      prob[i] = i * random(0, 1);
    }

    while (soundStorage.size() < maxVox) {
      float maiorValor = -1; // valores iniciais negativos para garantir que os primeiros records vão ser escolhidos
      int vencedorIndice = -1;
      
      // Procura quem teve a maior pontuação na lista
      for (int i = 0; i < totalOfVoices; i++) {
        if (prob[i] > maiorValor) {
          maiorValor = prob[i];
          vencedorIndice = i;
        }
      }
      
      // Se encontrámos um vencedor, carregamos o som e "anulamos" a sua pontuação
      if (vencedorIndice != -1) {
        String ficheiroVencedor = recordNameStorage.get(vencedorIndice);
        AudioPlayer player = minim.loadFile(ficheiroVencedor);
        int currentSlot = soundStorage.size();
        soundStorage.add(player);
        tempoProximaReproducao[currentSlot] = currentTime + pause;
        
        // Marcamos como -1 para que não seja escolhido novamente para a próxima vaga
        prob[vencedorIndice] = -1; 
      }else { // Safety measure: in case there's an error we leave the while
        break; 
      }
    }
  }
  
  println("Choir updated");
}
