<?php

class Game extends CI_Controller {

	public function __construct()
	{
		parent::__construct();
		$this->load->model('user_model');
	}

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

	public function validate()
	{
		$logged_in = $this->session->userdata('logged_in');
		if($logged_in === FALSE)
		{
			$newdata = prompt_login();
			$this->user_model->setAccount($newdata);
		}
		else {
			$account = $this->session->all_userdata();
        }
	}

	public function prompt_login()
	{
		$this->load->helper('form');
		$this->load->library('form_validation');

		$this->form_validation->set_rules('user', 'Username', 'required|is_unique[accounts.username]');
		$this->form_validation->set_rules('pass', 'Password', 'required');
		
		if ($this->form_validation->run() == FALSE && $this->user_model->isValidPass($this->input->post('user'), $this->input->post('pass'))){
			print '<script type="text/javascript">'; 
			print 'alert("Either the username does not exist or the password is incorrect for that usrname.")'; 
			print '</script>'; 
			$this->load->view('templates/login');	
		}
		else{
			$userData = array(
				'user' => $this->input->post('user'),
				'pass' => $this->input->post('pass'),
				'email' => $this->user_model->get_email(),//$this->input->post('email')
				'logged_in' => TRUE
			);
			return $userData;
		}
	}

	public function new_user()
	{
		$this->load->helper('form');
		$this->load->library('form_validation');

		$this->form_validation->set_rules('user', 'Username', 'required||max_length[12]|is_unique[accounts.username]');
		$this->form_validation->set_rules('pass', 'Password', 'required');
		$this->form_validation->set_rules('email', 'Email', 'required|valid_email|is_unique[accounts.email]');
		
		$data['title'] = 'Create an Account';

		if ($this->form_validation->run() == FALSE){
			$this->load->view('templates/header', $data);
			$this->load->view('templates/new_user', $data);	
		}
		else{
			$this->user_model->create_account();
			$this->load->view('news/success', $data);
		}

	}
	
	public function main($page = 'home')
	{
		$data['previous'] = ($page);
		$data['title'] = 'Game';

		$this->load->view('templates/header', $data);
		$this->load->view('pages/game', $data);
	}
}
?>