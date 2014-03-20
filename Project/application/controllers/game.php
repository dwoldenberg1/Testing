<?php

class Game extends CI_Controller {

	public function view($page = 'home')
	{
		if ( ! file_exists('application/views/pages/'.$page.'.php'))
		{
			// Whoops, we don't have a page for that!
			show_404();
		}

		$data['title'] = ucfirst($page); // Capitalize the first letter

		$this->load->view('templates/header', $data);
		$this->load->view('pages/'.$page, $data);
	}
	
	public function index()
	{
		echo 'wtf';

		//$this->load->view('templates/header', $data);
		$this->load->view('pages/game');
		//$this->load->view('templates/footer');
		
	}
	
	public function main($page = 'home')
	{
		$data['previous'] = ($page);
		$this->load->view('templates/header');
		$this->load->view('pages/game', $data);
	}
}
?>