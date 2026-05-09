package com.bushop.sg

import android.os.Bundle
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bushop.sg.data.api.RetrofitBusArrivalDataSource
import com.bushop.sg.data.local.BusStopIndex
import com.bushop.sg.data.local.BusStopStorage
import com.bushop.sg.data.repository.BusRepositoryImpl
import com.bushop.sg.domain.model.ThemeMode
import com.bushop.sg.ui.screens.MainScreen
import com.bushop.sg.ui.screens.MainViewModel
import com.bushop.sg.ui.theme.BusHopTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val storage = BusStopStorage(applicationContext)
        val dataSource = RetrofitBusArrivalDataSource()
        val busStopIndex = BusStopIndex(applicationContext).also { idx ->
            lifecycleScope.launch(Dispatchers.IO) { idx.load() }
        }
        val repository = BusRepositoryImpl(storage, dataSource, busStopIndex)
        val viewModelFactory = MainViewModel.Factory(repository, busStopIndex)

        setContent {
            val viewModel: MainViewModel = viewModel(factory = viewModelFactory)
            val themeMode by viewModel.themeModeFlow.collectAsState()
            val isDarkTheme = when (themeMode) {
                ThemeMode.SYSTEM -> isSystemInDarkTheme()
                ThemeMode.LIGHT -> false
                ThemeMode.DARK -> true
            }
            BusHopTheme(darkTheme = isDarkTheme) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen(viewModel = viewModel)
                }
            }
        }
    }
}
