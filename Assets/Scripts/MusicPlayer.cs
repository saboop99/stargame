using UnityEngine;

public class MusicPlayer : MonoBehaviour
{
    public AudioClip[] songs;
    private AudioSource audioSource;
    private int nowPlaying = 0;
    private int[] shuffledOrder;

    // Toca a primeira música assim que o jogo começar
    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        ShuffleOrder();
        PlaySongs(nowPlaying);
    }

    
    void Update()
    {
        // Condicional para quando acabar a primeira musica, ir para a próxima
        if (!audioSource.isPlaying)
        {
            //if (Input.GetKeyDown(KeyCode.N))
            //nowPlaying++;


            /*if (nowPlaying >= songs.Length)
                nowPlaying = 0; // volta para a primeira quando acabar*/

            //PlaySongs(nowPlaying);

            
                NextSong();

        }
    }

    private void NextSong()
    {
        nowPlaying++;

        // Quando terminar todas, embaralha de novo e volta do início
        if (nowPlaying >= shuffledOrder.Length)
        {
            ShuffleOrder();
            nowPlaying = 0;
        }

        PlaySongs(nowPlaying);
    }

    // Método que recebe o índice de se a música está tocando, define o audio no AudioSource e manda tocar
    private void PlaySongs(int index)
    {
        audioSource.clip = songs[shuffledOrder[index]];
        audioSource.Play();
    }

    private void ShuffleOrder()
    {
        shuffledOrder = new int[songs.Length];

        for (int i = 0; i < shuffledOrder.Length; i++)
            shuffledOrder[i] = i;

        // Fisher-Yates: percorre do fim ao início trocando cada posição com uma aleatória
        for (int i = shuffledOrder.Length - 1; i > 0; i--)
        {
            int j = Random.Range(0, i + 1);
            (shuffledOrder[i], shuffledOrder[j]) = (shuffledOrder[j], shuffledOrder[i]);
        }
    }
}
